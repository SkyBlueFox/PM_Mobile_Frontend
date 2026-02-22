// lib/features/home/bloc/devices_bloc.dart
//
// แก้ “ให้ไม่ error / คอมไพล์ผ่าน / ทำงานปกติ”
//
// จุดที่แก้หลัก ๆ (เพื่อความเสถียร):
// 1) ลบโค้ด serialize/deserialize ที่ทำให้ error แน่ ๆ (toMap/fromMap/toJson/hashCode/==)
//    เพราะ Repository/Timer ไม่มี toMap/fromMap และโดยปกติ BLoC ไม่ควรถูก serialize
// 2) ปรับ constructor ให้เรียบง่าย (ไม่รับ pollInFlight/pollTimer จากภายนอก)
// 3) _pollOnce() ใช้ `emit(...)` ได้โดยตรงภายใน Bloc (ไม่ต้องมี Emitter ใน scope) และกันซ้อนด้วย _pollInFlight
// 4) commit reorder: กัน selectedRoomId == null (ไม่ crash)
// 5) ลบ import dart:convert ที่ไม่จำเป็นหลังลบ serialize

// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/device_repository.dart';
import '../../../data/room_repository.dart';
import '../data/widget_repository.dart';
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

  // กัน polling overwrite ค่าที่ user เพิ่งสั่ง (snap-back)
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

    // รองรับ mode/text/button
    on<WidgetModeChanged>(_onWidgetModeChanged);
    on<WidgetTextSubmitted>(_onWidgetTextSubmitted);
    on<WidgetButtonPressed>(_onWidgetButtonPressed);

    on<DevicesAllToggled>(_onAllToggled);

    on<ReorderModeChanged>(_onReorderModeChanged);
    on<WidgetsOrderChanged>(_onWidgetsOrderChanged);
    on<CommitReorderPressed>(_onCommitReorderPressed);
    on<DevicesRequested>(_onDevicesRequested);

    on<WidgetsPollingStarted>(_onWidgetsPollingStarted);
    on<WidgetsPollingStopped>(_onWidgetsPollingStopped);

    // include/exclude selection
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

      // merge pending (กัน snap-back) ตอนเปลี่ยนห้องด้วย
      final merged = _mergePending(widgets);

      emit(state.copyWith(isLoading: false, widgets: merged, error: null));
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

      _clearPending(event.widgetId);
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

    _markPending(event.widgetId, newValueStr);

    final updated = List<DeviceWidget>.from(before);
    updated[idx] = target.copyWith(value: newValueStr);

    emit(state.copyWith(widgets: updated, error: null));

    try {
      final w = updated[idx];
      await widgetRepo.sendWidgetCommand(
        widgetId: w.widgetId,
        capabilityId: w.capability.id,
        value: w.value,
      );

      _clearPending(event.widgetId);
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

    _markPending(event.widgetId, mode);

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
      _clearPending(event.widgetId);
    } catch (e, st) {
      debugPrint('[DevicesBloc] mode send failed: $e\n$st');
      _clearPending(event.widgetId);
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

    final text = event.text; // อนุญาตให้เป็น "" ได้

    _markPending(event.widgetId, text);

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
      _clearPending(event.widgetId);
    } catch (e, st) {
      debugPrint('[DevicesBloc] text send failed: $e\n$st');
      _clearPending(event.widgetId);
      emit(state.copyWith(widgets: before, error: _msgCommandFailed));
    }
  }

  Future<void> _onWidgetButtonPressed(WidgetButtonPressed event, Emitter<DevicesState> emit) async {
    if (state.reorderLocked) return;

    final target = state.widgets.where((w) => w.widgetId == event.widgetId).toList();
    if (target.isEmpty) return;

    final w = target.first;
    if (w.capability.type != CapabilityType.button) return;

    try {
      await widgetRepo.sendWidgetCommand(
        widgetId: w.widgetId,
        capabilityId: w.capability.id,
        value: event.value, // ปกติส่ง "1" หรือ "press"
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

    // ✅ กัน null roomId (ถ้า reorder ใน All)
    final roomId = state.selectedRoomId;
    if (roomId == null) {
      emit(state.copyWith(
        reorderSaving: false,
        error: 'Please select a room before saving order.',
      ));
      return;
    }

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
      await widgetRepo.changeWidgetsOrder(
        roomId: roomId,
        widgetOrders: workingIds,
      );

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
        error: _msgSaveFailed,
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

    await _pollOnce(); // immediate
  }

  Future<void> _onWidgetsPollingStopped(
    WidgetsPollingStopped event,
    Emitter<DevicesState> emit,
  ) async {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    if (_pollInFlight) return;
    _pollInFlight = true;

    try {
      // ถ้า reorder อยู่ ให้ skip (กัน UI กระพริบ/สลับลำดับ)
      if (state.reorderEnabled || state.reorderSaving) return;

      _cleanupExpiredPending();

      final serverWidgets = (_pollRoomId == null)
          ? await widgetRepo.fetchWidgets()
          : await roomRepo.fetchWidgetsByRoomId(_pollRoomId!);

      final merged = _mergePending(serverWidgets);

      // ✅ emit ได้โดยตรงใน Bloc (ไม่ต้องมี Emitter ใน scope)
      emit(state.copyWith(widgets: merged, error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    } finally {
      _pollInFlight = false;
    }
  }

  List<DeviceWidget> _mergePending(List<DeviceWidget> serverWidgets) {
    return serverWidgets.map((sw) {
      final pending = _pendingValueByWidgetId[sw.widgetId];
      if (pending != null) {
        return sw.copyWith(value: pending);
      }
      return sw;
    }).toList(growable: false);
  }

  // ------------------------------
  // include/exclude selection
  // ------------------------------

  Future<void> _onWidgetSelectionLoaded(
    WidgetSelectionLoaded event,
    Emitter<DevicesState> emit,
  ) async {
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
    // ถ้าคุณยิง backend ทีละตัวแล้ว อันนี้แค่ refresh ให้ชัวร์
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

  // ------------------------------
  // pending helpers
  // ------------------------------

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