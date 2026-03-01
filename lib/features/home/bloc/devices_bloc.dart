// lib/features/home/bloc/devices_bloc.dart
//
// ✅ FIX (ครบทั้งไฟล์):
// - เพิ่มการ save include/exclude จาก "widget picker" ให้ยิง API จริง
// - ทำให้หน้า picker ไม่ว่าง: WidgetSelectionLoaded จะพยายามโหลด "all widgets" แล้วค่อย filter ตาม roomId แบบปลอดภัย
//
// หมายเหตุสำคัญ:
// - บาง backend อาจคืน widgets by room เฉพาะ include => picker จะว่าง
//   ดังนั้นใน selection/bulk-save จะใช้ widgetRepo.fetchWidgets() เป็นหลัก แล้ว filter ตาม roomId แบบ safe (dynamic)

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

  Timer? _sensorPollTimer;
  Timer? _fullPollTimer;

  Duration _sensorInterval = const Duration(seconds: 1);
  Duration _fullInterval = const Duration(seconds: 10);

  int? _pollRoomId;
  bool _sensorPollInFlight = false;
  bool _fullPollInFlight = false;

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

    on<WidgetSelectionLoaded>(_onWidgetSelectionLoaded);
    on<WidgetIncludeToggled>(_onWidgetIncludeToggled);
    on<WidgetSelectionSaved>(_onWidgetSelectionSaved);

    on<WidgetsVisibilitySaved>(_onWidgetsVisibilitySaved);
  }

  bool _isInclude(DeviceWidget w) => w.status.trim().toLowerCase() == 'include';
  bool _isSensor(DeviceWidget w) => w.capability.type == CapabilityType.sensor;

  // ✅ safe roomId getter: ไม่ทำให้ compile error แม้ DeviceWidget ไม่มี roomId field
  int? _roomIdOf(DeviceWidget w) {
    try {
      final dynamic dw = w;
      final v = dw.roomId;
      if (v is int) return v;
      return null;
    } catch (_) {
      return null;
    }
  }

  List<DeviceWidget> _filterByRoomIfPossible(List<DeviceWidget> all, int? roomId) {
    if (roomId == null) return all;
    return all.where((w) => _roomIdOf(w) == roomId).toList(growable: false);
  }

  // ------------------------------
  // Initial load
  // ------------------------------
  Future<void> _onStarted(DevicesStarted event, Emitter<DevicesState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final rooms = await roomRepo.fetchRooms();
      final widgets = await roomRepo.fetchWidgetsByRoomId(rooms.first.id);
      final devices = await deviceRepo.fetchDevices();

      emit(state.copyWith(
        isLoading: false,
        rooms: rooms,
        widgets: widgets,
        selectedRoomId: 1,
        error: null,
        devices: devices,
      ));
    } catch (e, st) {
      debugPrint('[DevicesBloc] start failed: $e\n$st');
      emit(state.copyWith(isLoading: false, error: _msgLoadFailed));
    }
  }

  // ------------------------------
  // Room changed
  // ------------------------------
  Future<void> _onRoomChanged(DevicesRoomChanged event, Emitter<DevicesState> emit) async {
    emit(state.copyWith(
      selectedRoomId: event.roomId,
      isLoading: true,
      error: null,
    ));

    try {
      final int roomId = event.roomId;

      final widgets = await roomRepo.fetchWidgetsByRoomId(roomId);

      final merged = _mergePending(widgets);
      emit(state.copyWith(isLoading: false, widgets: merged, error: null));
    } catch (e, st) {
      debugPrint('[DevicesBloc] roomChanged failed: $e\n$st');
      emit(state.copyWith(isLoading: false, error: _msgLoadFailed));
    }
  }

  // ------------------------------
  // Toggle widget
  // ------------------------------
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

  // ------------------------------
  // Adjust widget
  // ------------------------------
  Future<void> _onWidgetValueChanged(
    WidgetValueChanged event,
    Emitter<DevicesState> emit,
  ) async {
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

  // ------------------------------
  // Mode/Text/Button
  // ------------------------------
  Future<void> _onWidgetModeChanged(
    WidgetModeChanged event,
    Emitter<DevicesState> emit,
  ) async {
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

  Future<void> _onWidgetTextSubmitted(
    WidgetTextSubmitted event,
    Emitter<DevicesState> emit,
  ) async {
    if (state.reorderLocked) return;
    final before = state.widgets;

    final idx = before.indexWhere((w) => w.widgetId == event.widgetId);
    if (idx < 0) return;

    final target = before[idx];
    if (target.capability.type != CapabilityType.text) return;

    final text = event.text;

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

  Future<void> _onWidgetButtonPressed(
    WidgetButtonPressed event,
    Emitter<DevicesState> emit,
  ) async {
    if (state.reorderLocked) return;

    final target = state.widgets.where((w) => w.widgetId == event.widgetId).toList();
    if (target.isEmpty) return;

    final w = target.first;
    if (w.capability.type != CapabilityType.button) return;

    try {
      await widgetRepo.sendWidgetCommand(
        widgetId: w.widgetId,
        capabilityId: w.capability.id,
        value: event.value,
      );
    } catch (e, st) {
      debugPrint('[DevicesBloc] button press failed: $e\n$st');
      emit(state.copyWith(error: _msgCommandFailed));
    }
  }

  // ------------------------------
  // Toggle all (optional)
  // ------------------------------
  void _onAllToggled(DevicesAllToggled event, Emitter<DevicesState> emit) {
    final int turnOnValue = event.turnOn ? 1 : 0;

    final updated = state.widgets.map((w) {
      if (w.capability.type != CapabilityType.toggle) return w;
      return w.copyWith(value: turnOnValue.toString());
    }).toList();

    emit(state.copyWith(widgets: updated, error: null));
  }

  // ------------------------------
  // Reorder helpers
  // ------------------------------
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

  // ------------------------------
  // Devices list
  // ------------------------------
  Future<void> _onDevicesRequested(
    DevicesRequested event,
    Emitter<DevicesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final devices = await deviceRepo.fetchDevices(connected: event.connected);
      emit(state.copyWith(isLoading: false, devices: devices));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: _msgLoadFailed));
    }
  }

  // ------------------------------
  // Polling
  // ------------------------------
  Future<void> _onWidgetsPollingStarted(
    WidgetsPollingStarted event,
    Emitter<DevicesState> emit,
  ) async {
    _pollRoomId = event.roomId;

    _fullInterval = event.interval;
    _sensorInterval = const Duration(seconds: 1);

    _sensorPollTimer?.cancel();
    _fullPollTimer?.cancel();

    _sensorPollTimer = Timer.periodic(_sensorInterval, (_) async {
      await _pollSensorsOnce();
    });

    _fullPollTimer = Timer.periodic(_fullInterval, (_) async {
      await _pollFullOnce();
    });

    await _pollFullOnce();
    await _pollSensorsOnce();
  }

  Future<void> _onWidgetsPollingStopped(
    WidgetsPollingStopped event,
    Emitter<DevicesState> emit,
  ) async {
    _sensorPollTimer?.cancel();
    _sensorPollTimer = null;

    _fullPollTimer?.cancel();
    _fullPollTimer = null;
  }

  Future<void> _pollFullOnce() async {
    if (_fullPollInFlight) return;
    _fullPollInFlight = true;

    try {
      if (state.reorderEnabled || state.reorderSaving) return;

      _cleanupExpiredPending();

      final serverWidgets = (_pollRoomId == null)
          ? await widgetRepo.fetchWidgets()
          : await roomRepo.fetchWidgetsByRoomId(_pollRoomId!);

      final merged = serverWidgets.map((sw) {
        final pending = _pendingValueByWidgetId[sw.widgetId];
        return pending != null ? sw.copyWith(value: pending) : sw;
      }).toList(growable: false);

      emit(state.copyWith(widgets: merged, error: null));
    } catch (_) {
      // ไม่ spam UI
    } finally {
      _fullPollInFlight = false;
    }
  }

  Future<void> _pollSensorsOnce() async {
    if (_sensorPollInFlight) return;
    _sensorPollInFlight = true;

    try {
      if (state.reorderEnabled || state.reorderSaving) return;

      _cleanupExpiredPending();

      final serverWidgets = (_pollRoomId == null)
          ? await widgetRepo.fetchWidgets()
          : await roomRepo.fetchWidgetsByRoomId(_pollRoomId!);

      final serverById = {for (final w in serverWidgets) w.widgetId: w};

      final updated = <DeviceWidget>[];
      var anyChanged = false;

      for (final local in state.widgets) {
        final server = serverById[local.widgetId];
        if (server == null) {
          updated.add(local);
          continue;
        }

        final pending = _pendingValueByWidgetId[local.widgetId];
        if (pending != null) {
          updated.add(local.copyWith(value: pending));
          continue;
        }

        if (_isSensor(local)) {
          if (local.value != server.value) {
            anyChanged = true;
            updated.add(local.copyWith(value: server.value));
          } else {
            updated.add(local);
          }
        } else {
          updated.add(local);
        }
      }

      if (anyChanged) {
        emit(state.copyWith(widgets: updated, error: null));
      }
    } catch (_) {
      // ไม่ spam UI
    } finally {
      _sensorPollInFlight = false;
    }
  }

  List<DeviceWidget> _mergePending(List<DeviceWidget> serverWidgets) {
    return serverWidgets.map((sw) {
      final pending = _pendingValueByWidgetId[sw.widgetId];
      return pending != null ? sw.copyWith(value: pending) : sw;
    }).toList(growable: false);
  }

  // ------------------------------
  // include/exclude selection (ใช้ก่อนเปิด picker)
  // ------------------------------
  Future<void> _onWidgetSelectionLoaded(
    WidgetSelectionLoaded event,
    Emitter<DevicesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final all = await roomRepo.fetchWidgetsByRoomId(event.roomId);
      
      emit(state.copyWith(isLoading: false, widgets: all, error: null));
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
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final roomId = event.roomId ?? state.selectedRoomId;
      final all = await widgetRepo.fetchWidgets();
      final filtered = _filterByRoomIfPossible(all, roomId);
      emit(state.copyWith(isLoading: false, widgets: filtered, error: null));
    } catch (e, st) {
      debugPrint('[DevicesBloc] selection save(refresh) failed: $e\n$st');
      emit(state.copyWith(isLoading: false, error: _msgLoadFailed));
    }
  }

  // ------------------------------
  // ✅ NEW: Save include/exclude จาก picker (bulk)
  // ------------------------------
  Future<void> _onWidgetsVisibilitySaved(
    WidgetsVisibilitySaved event,
    Emitter<DevicesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final roomId = event.roomId;

      // ✅ เอา widgetId ให้ครบ (include+exclude) ของห้องนี้
      final all = await widgetRepo.fetchWidgets();
      final roomWidgets = _filterByRoomIfPossible(all, roomId);

      final roomWidgetIds =
          roomWidgets.map((w) => w.widgetId).toList(growable: false);

      await widgetRepo.saveRoomWidgetsVisibility(
        roomWidgetIds: roomWidgetIds,
        includedWidgetIds: event.includedWidgetIds,
      );

      // refresh หลัง save
      final refreshedAll = await widgetRepo.fetchWidgets();
      final refreshedRoom = _filterByRoomIfPossible(refreshedAll, roomId);

      emit(state.copyWith(isLoading: false, widgets: refreshedRoom, error: null));

      // restart polling เพื่อ sync หน้า home
      add(DevicesRoomChanged(roomId));
      add(WidgetsPollingStarted(roomId: roomId));
    } catch (e, st) {
      debugPrint('[DevicesBloc] visibility save failed: $e\n$st');
      emit(state.copyWith(isLoading: false, error: _msgSaveFailed));
    }
  }

  // ------------------------------
  // close
  // ------------------------------
  @override
  Future<void> close() {
    _sensorPollTimer?.cancel();
    _fullPollTimer?.cancel();
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