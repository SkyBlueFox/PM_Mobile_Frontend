// lib/features/home/bloc/devices_bloc.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/device_repository.dart';
import '../../../data/room_repository.dart';
import '../../../data/widget_repository.dart';
import '../models/capability.dart';
import '../models/device_widget.dart';
import 'devices_event.dart';
import 'devices_state.dart';

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  final WidgetRepository widgetRepo;
  final RoomRepository roomRepo;
  final DeviceRepository deviceRepo;

  static const String _msgLoadFailed = 'Unable to load data. Please try again.';
  static const String _msgCommandFailed = 'Unable to send command. Please try again.';
  static const String _msgSaveFailed = 'Unable to save. Please try again.';

  Timer? _pollTimer;
  bool _pollInFlight = false;
  int? _pollRoomId;
  Duration _pollInterval = const Duration(seconds: 5);

  final Map<int, String> _pendingValueByWidgetId = {};
  final Map<int, DateTime> _pendingAtByWidgetId = {};
  static const _pendingTtl = Duration(seconds: 10);

  DevicesBloc({
    required this.widgetRepo,
    required this.roomRepo,
    required this.deviceRepo,
  }) : super(const DevicesState()) {
    on<DevicesStarted>(_onStarted);
    on<DevicesRoomChanged>(_onRoomChanged);

    on<WidgetToggled>(_onWidgetToggled);
    on<WidgetValueChanged>(_onWidgetValueChanged);

    // ✅ เพิ่มให้รองรับครบ
    on<WidgetModeChanged>(_onWidgetModeChanged);
    on<WidgetTextSubmitted>(_onWidgetTextSubmitted);
    on<WidgetButtonPressed>(_onWidgetButtonPressed);

    on<DevicesAllToggled>(_onAllToggled);

    on<ReorderModeChanged>(_onReorderModeChanged);
    on<WidgetsOrderChanged>(_onWidgetsOrderChanged);
    on<CommitReorderPressed>(_onCommitReorderPressed);
    on<DevicesRequested>(_onDevicesRequested);

    on<RoomCreateRequested>(_onRoomCreateRequested);
    on<WidgetsPollingStarted>(_onWidgetsPollingStarted);
    on<WidgetsPollingStopped>(_onWidgetsPollingStopped);

    // ✅ include/exclude (selection) ที่คุณมี event อยู่แล้ว แต่เดิมไม่ได้ on(...)
    on<WidgetSelectionLoaded>(_onWidgetSelectionLoaded);
    on<WidgetIncludeToggled>(_onWidgetIncludeToggled);
    on<WidgetSelectionSaved>(_onWidgetSelectionSaved);
  }

  bool _isInclude(DeviceWidget w) => w.status.trim().toLowerCase() == 'include';

  Future<void> _onStarted(DevicesStarted event, Emitter<DevicesState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final rooms = await roomRepo.fetchRooms();
      final widgets = await widgetRepo.fetchWidgets();
      final devices = await deviceRepo.fetchDevices();

      emit(state.copyWith(
        isLoading: false,
        rooms: rooms,
        widgets: widgets,
        selectedRoomId: null,
        error: null,
        devices: devices,
      ));
    } catch (e, st) {
      debugPrint('[DevicesBloc] start failed: $e\n$st');
      emit(state.copyWith(isLoading: false, error: _msgLoadFailed));
    }
  }

  Future<void> _onRoomChanged(DevicesRoomChanged event, Emitter<DevicesState> emit) async {
    emit(state.copyWith(
      selectedRoomId: event.roomId,
      isLoading: true,
      error: null,
    ));

    try {
      final int? roomId = event.roomId;

      final widgets = roomId == null
          ? await widgetRepo.fetchWidgets()
          : await roomRepo.fetchWidgetsByRoomId(roomId);

      emit(state.copyWith(isLoading: false, widgets: widgets, error: null));
    } catch (e, st) {
      debugPrint('[DevicesBloc] roomChanged failed: $e\n$st');
      emit(state.copyWith(isLoading: false, error: _msgLoadFailed));
    }
  }

  Future<void> _onWidgetToggled(WidgetToggled event, Emitter<DevicesState> emit) async {
    if (state.reorderLocked) return;
    final before = state.widgets;

    final idx = before.indexWhere((w) => w.widgetId == event.widgetId);
    if (idx < 0) return;

    final target = before[idx];
    if (target.capability.type != CapabilityType.toggle) return;

    final double? doubleValue = double.tryParse(target.value);
    final int intValue = doubleValue?.round() ?? 0;
    final int newValue = intValue >= 1 ? 0 : 1;

    final updated = List<DeviceWidget>.from(before);
    updated[idx] = target.copyWith(value: newValue.toString());

    // mark pending so polling won't overwrite
    _markPending(event.widgetId, newValue.toString());

    emit(state.copyWith(widgets: updated, error: null));

    try {
      final w = updated[idx];
      await widgetRepo.sendWidgetCommand(
        widgetId: w.widgetId,
        capabilityId: w.capability.id,
        value: w.value,
      );

      // success: clear pending (optional: poll once to sync)
      _clearPending(event.widgetId);
      // await _pollOnce();
    } catch (e, st) {
      debugPrint('[DevicesBloc] toggle send failed: $e\n$st');
      _clearPending(event.widgetId);
      emit(state.copyWith(widgets: before, error: _msgCommandFailed));
    }
  }

  Future<void> _onWidgetValueChanged(WidgetValueChanged event, Emitter<DevicesState> emit) async {
    if (state.reorderLocked) return;
    final before = state.widgets;

    final idx = before.indexWhere((w) => w.widgetId == event.widgetId);
    if (idx < 0) return;

    final target = before[idx];
    if (target.capability.type != CapabilityType.adjust) return;

    final int v = (event.value as num).round();
    final newValueStr = v.toString();

    // mark pending before sending
    _markPending(event.widgetId, newValueStr);

    final updated = List<DeviceWidget>.from(before);
    updated[idx] = target.copyWith(value: v.toString());

    emit(state.copyWith(widgets: updated, error: null));

    try {
      final w = updated[idx];
      await widgetRepo.sendWidgetCommand(
        widgetId: w.widgetId,
        capabilityId: w.capability.id,
        value: w.value,
      );

      _clearPending(event.widgetId);
      // await _pollOnce();
    } catch (e, st) {
      debugPrint('[DevicesBloc] adjust send failed: $e\n$st');
      _clearPending(event.widgetId);
      emit(state.copyWith(widgets: before, error: _msgCommandFailed));
    }
  }

  Future<void> _onWidgetModeChanged(WidgetModeChanged event, Emitter<DevicesState> emit) async {
    if (state.reorderLocked) return;
    final before = state.widgets;

    final idx = before.indexWhere((w) => w.widgetId == event.widgetId);
    if (idx < 0) return;

    final target = before[idx];
    if (target.capability.type != CapabilityType.mode) return;

    final mode = event.mode.trim();
    if (mode.isEmpty) return;

    final updated = List<DeviceWidget>.from(before);
    updated[idx] = target.copyWith(value: mode);

    emit(state.copyWith(widgets: updated, error: null));

    try {
      final w = updated[idx];
      await widgetRepo.sendWidgetCommand(
        widgetId: w.widgetId,
        capabilityId: w.capability.id,
        value: w.value,
      );
    } catch (e, st) {
      debugPrint('[DevicesBloc] mode send failed: $e\n$st');
      emit(state.copyWith(widgets: before, error: _msgCommandFailed));
    }
  }

  Future<void> _onWidgetTextSubmitted(WidgetTextSubmitted event, Emitter<DevicesState> emit) async {
    if (state.reorderLocked) return;
    final before = state.widgets;

    final idx = before.indexWhere((w) => w.widgetId == event.widgetId);
    if (idx < 0) return;

    final target = before[idx];
    if (target.capability.type != CapabilityType.text) return;

    final text = event.text; // อนุญาตให้เป็น "" ได้ (บาง device ต้องการล้างข้อความ)

    final updated = List<DeviceWidget>.from(before);
    updated[idx] = target.copyWith(value: text);

    emit(state.copyWith(widgets: updated, error: null));

    try {
      final w = updated[idx];
      await widgetRepo.sendWidgetCommand(
        widgetId: w.widgetId,
        capabilityId: w.capability.id,
        value: w.value,
      );
    } catch (e, st) {
      debugPrint('[DevicesBloc] text send failed: $e\n$st');
      emit(state.copyWith(widgets: before, error: _msgCommandFailed));
    }
  }

  Future<void> _onWidgetButtonPressed(WidgetButtonPressed event, Emitter<DevicesState> emit) async {
    if (state.reorderLocked) return;
    final before = state.widgets;

    final idx = before.indexWhere((w) => w.widgetId == event.widgetId);
    if (idx < 0) return;

    final target = before[idx];
    if (target.capability.type != CapabilityType.button) return;

    // ปุ่มกดครั้งเดียว: ปกติไม่จำเป็นต้องเปลี่ยน value ใน state (เพราะเป็น momentary)
    try {
      await widgetRepo.sendWidgetCommand(
        widgetId: target.widgetId,
        capabilityId: target.capability.id,
        value: event.value,
      );
    } catch (e, st) {
      debugPrint('[DevicesBloc] button press failed: $e\n$st');
      emit(state.copyWith(error: _msgCommandFailed));
    }
  }

  void _onAllToggled(DevicesAllToggled event, Emitter<DevicesState> emit) {
    final int turnOnValue = event.turnOn ? 1 : 0;

    final updated = state.widgets.map((w) {
      if (w.capability.type != CapabilityType.toggle) return w;
      return w.copyWith(value: turnOnValue.toString());
    }).toList();

    emit(state.copyWith(widgets: updated, error: null));
  }

  List<int> _currentVisibleIds(List<DeviceWidget> all) {
    final visible = all.where(_isInclude).toList();
    visible.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      return a.widgetId.compareTo(b.widgetId);
    });
    return visible.map((e) => e.widgetId).toList();
  }

  void _onReorderModeChanged(ReorderModeChanged event, Emitter<DevicesState> emit) {
    if (event.enabled) {
      final ids = _currentVisibleIds(state.widgets);
      emit(state.copyWith(
        reorderEnabled: true,
        reorderSaving: false,
        reorderOriginalVisibleIds: ids,
        reorderWorkingVisibleIds: List<int>.from(ids),
        error: null,
      ));
    } else {
      emit(state.copyWith(
        reorderEnabled: false,
        reorderSaving: false,
        reorderWorkingVisibleIds: const [],
        reorderOriginalVisibleIds: const [],
        error: null,
      ));
    }
  }

  void _onWidgetsOrderChanged(WidgetsOrderChanged event, Emitter<DevicesState> emit) {
    if (!state.reorderEnabled || state.reorderSaving) return;

    emit(state.copyWith(
      reorderWorkingVisibleIds: List<int>.from(event.orderedWidgetIds),
      error: null,
    ));
  }

  Future<void> _onCommitReorderPressed(
    CommitReorderPressed event,
    Emitter<DevicesState> emit,
  ) async {
    if (!state.reorderEnabled) return;

    if (!state.reorderDirty) {
      emit(state.copyWith(
        reorderEnabled: false,
        reorderSaving: false,
        reorderOriginalVisibleIds: const [],
        reorderWorkingVisibleIds: const [],
        error: null,
      ));
      return;
    }

    emit(state.copyWith(reorderSaving: true, error: null));

    final workingIds = state.reorderWorkingVisibleIds;

    final orderIndex = <int, int>{};
    for (var i = 0; i < workingIds.length; i++) {
      orderIndex[workingIds[i]] = i;
    }

    // update local order field (UI stable)
    final updatedWidgets = state.widgets.map((w) {
      final idx = orderIndex[w.widgetId];
      if (idx == null) return w;
      return w.copyWith(order: idx);
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));

    try {
      // backend expects list of include widgetIds in new order
      await widgetRepo.changeWidgetsOrder(workingIds);

      emit(state.copyWith(
        reorderEnabled: false,
        reorderSaving: false,
        reorderOriginalVisibleIds: const [],
        reorderWorkingVisibleIds: const [],
        error: null,
      ));
    } catch (e, st) {
      debugPrint('[DevicesBloc] commit reorder failed: $e\n$st');
      emit(state.copyWith(
        reorderSaving: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDevicesRequested(
    DevicesRequested event,
    Emitter<DevicesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final devices = await deviceRepo.fetchDevices();
      emit(state.copyWith(isLoading: false, devices: devices));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: _msgLoadFailed));
    }
  }

  Future<void> _onRoomCreateRequested(
    RoomCreateRequested event,
    Emitter<DevicesState> emit,
  ) async {
    final name = event.roomName.trim();
    if (name.isEmpty) return;

    emit(state.copyWith(isLoading: true, error: null));

    try {
      await roomRepo.createRoom(roomName: name);

      final rooms = await roomRepo.fetchRooms();

      emit(state.copyWith(
        isLoading: false,
        rooms: rooms,
        error: null,
      ));
    } catch (e, st) {
      debugPrint('[DevicesBloc] create room failed: $e\n$st');
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onWidgetsPollingStarted(
    WidgetsPollingStarted event,
    Emitter<DevicesState> emit,
  ) async {
    _pollRoomId = event.roomId;
    _pollInterval = event.interval;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      await _pollOnce();
    });

    // immediate fetch
    await _pollOnce();
  }

  Future<void> _onWidgetsPollingStopped(
    WidgetsPollingStopped event,
    Emitter<DevicesState> emit,
  ) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    print( 'Stopped polling widgets at ${DateTime.now()}');
  }

  Future<void> _pollOnce() async {
    if (_pollInFlight) return;
    _pollInFlight = true;

    try {
      if (state.reorderEnabled || state.reorderSaving) return;

      _cleanupExpiredPending();

      final serverWidgets = (_pollRoomId == null)
          ? await widgetRepo.fetchWidgets()
          : await roomRepo.fetchWidgetsByRoomId(_pollRoomId!);

      final merged = serverWidgets.map((sw) {
        final pending = _pendingValueByWidgetId[sw.widgetId];

        // If user has an in-flight command for this widget,
        // keep the pending value (prevents snapping back).
        if (pending != null) {
          return sw.copyWith(value: pending);
        }

        return sw;
      }).toList();

      // Optional: avoid rebuild if nothing changed
      // (implement a cheap comparison if you want)
      emit(state.copyWith(widgets: merged, error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    } finally {
      _pollInFlight = false;
    }
  }

  /// ------------------------------
  /// include/exclude selection
  /// ------------------------------

  Future<void> _onWidgetSelectionLoaded(
    WidgetSelectionLoaded event,
    Emitter<DevicesState> emit,
  ) async {
    // โหลด list ล่าสุด (สำหรับเปิด drawer/picker ให้ไม่ stale)
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final roomId = event.roomId ?? state.selectedRoomId;

      final widgets = roomId == null
          ? await widgetRepo.fetchWidgets()
          : await roomRepo.fetchWidgetsByRoomId(roomId);

      emit(state.copyWith(isLoading: false, widgets: widgets, error: null));
    } catch (e, st) {
      debugPrint('[DevicesBloc] selection load failed: $e\n$st');
      emit(state.copyWith(isLoading: false, error: _msgLoadFailed));
    }
  }

  Future<void> _onWidgetIncludeToggled(
    WidgetIncludeToggled event,
    Emitter<DevicesState> emit,
  ) async {
    final before = state.widgets;
    final idx = before.indexWhere((w) => w.widgetId == event.widgetId);
    if (idx < 0) return;

    final target = before[idx];
    final newStatus = event.included ? 'include' : 'exclude';

    // optimistic update
    final updated = List<DeviceWidget>.from(before);
    updated[idx] = target.copyWith(status: newStatus);
    emit(state.copyWith(widgets: updated, error: null));

    try {
      await widgetRepo.changeWidgetStatus(
        widgetId: target.widgetId,
        widgetStatus: newStatus,
      );
    } catch (e, st) {
      debugPrint('[DevicesBloc] include toggle failed: $e\n$st');
      emit(state.copyWith(widgets: before, error: _msgSaveFailed));
    }
  }

  Future<void> _onWidgetSelectionSaved(
    WidgetSelectionSaved event,
    Emitter<DevicesState> emit,
  ) async {
    // ถ้าคุณ update status ทีละตัวแล้วใน _onWidgetIncludeToggled
    // อันนี้ไม่จำเป็นต้องยิง backend เพิ่ม แค่ refresh ให้ชัวร์ก็พอ
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final roomId = event.roomId ?? state.selectedRoomId;

      final widgets = roomId == null
          ? await widgetRepo.fetchWidgets()
          : await roomRepo.fetchWidgetsByRoomId(roomId);

      emit(state.copyWith(isLoading: false, widgets: widgets, error: null));
    } catch (e, st) {
      debugPrint('[DevicesBloc] selection save(refresh) failed: $e\n$st');
      emit(state.copyWith(isLoading: false, error: _msgLoadFailed));
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _pollTimer = null;
    return super.close();
  }

  void _markPending(int widgetId, String value) {
    _pendingValueByWidgetId[widgetId] = value;
    _pendingAtByWidgetId[widgetId] = DateTime.now();
  }

  void _clearPending(int widgetId) {
    _pendingValueByWidgetId.remove(widgetId);
    _pendingAtByWidgetId.remove(widgetId);
  }

  void _cleanupExpiredPending() {
    final now = DateTime.now();
    final expired = _pendingAtByWidgetId.entries
        .where((e) => now.difference(e.value) > _pendingTtl)
        .map((e) => e.key)
        .toList();

    for (final id in expired) {
      _clearPending(id);
    }
  }
}