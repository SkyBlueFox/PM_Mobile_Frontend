// lib/features/home/bloc/devices_bloc.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/device_repository.dart';
import '../data/room_repository.dart';
import '../data/widget_repository.dart';
import '../models/capability.dart';
import '../models/device_widget.dart';
import '../models/room.dart';
import 'devices_event.dart';
import 'devices_state.dart';

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  final WidgetRepository widgetRepo;
  final RoomRepository roomRepo;
  final DeviceRepository deviceRepo;

  static const String _msgLoadFailed = 'Unable to load data. Please try again.';
  static const String _msgCommandFailed = 'Unable to send command. Please try again.';

  Timer? _pollTimer;
  bool _pollInFlight = false;
  int? _pollRoomId;
  Duration _pollInterval = const Duration(seconds: 5);

  DevicesBloc({
    required this.widgetRepo,
    required this.roomRepo,
    required this.deviceRepo,
  }) : super(const DevicesState()) {
    on<DevicesStarted>(_onStarted);
    on<DevicesRoomChanged>(_onRoomChanged);
    on<WidgetToggled>(_onWidgetToggled);
    on<WidgetValueChanged>(_onWidgetValueChanged);
    on<DevicesAllToggled>(_onAllToggled);

    on<ReorderModeChanged>(_onReorderModeChanged);
    on<WidgetsOrderChanged>(_onWidgetsOrderChanged);
    on<CommitReorderPressed>(_onCommitReorderPressed);
    on<DevicesRequested>(_onDevicesRequested);

    on<RoomCreateRequested>(_onRoomCreateRequested);
    on<WidgetsPollingStarted>(_onWidgetsPollingStarted);
    on<WidgetsPollingStopped>(_onWidgetsPollingStopped);
  }

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

    // ✅ ใช้ int แทน double
    final double? doubleValue = double.tryParse(target.value);
    final int intValue = doubleValue?.round() ?? 0;
    final int newValue = intValue >= 1 ? 0 : 1;

    final updated = List<DeviceWidget>.from(before);
    updated[idx] = target.copyWith(value: newValue.toString());

    emit(state.copyWith(widgets: updated, error: null));

    try {
      final w = updated[idx];
      await widgetRepo.sendWidgetCommand(
        widgetId: w.widgetId,
        capabilityId: w.capability.id,
        value: w.value,
      );
    } catch (e, st) {
      debugPrint('[DevicesBloc] toggle send failed: $e\n$st');
      emit(state.copyWith(widgets: before, error: _msgCommandFailed));
    }
  }

  Future<void> _onWidgetValueChanged(WidgetValueChanged event, Emitter<DevicesState> emit) async {
    if (state.reorderLocked) return;
    final before = state.widgets;

    final deviceId = _deviceIdOf(before, event.widgetId);
    if (deviceId == null) return;

    // ✅ กันชนิดไม่ตรง: ถ้า event.value เป็น double ก็ปัดเป็น int ก่อน
    final int v = (event.value as num).round();

    final updated = before.map((w) {
      if (w.widgetId == event.widgetId && w.capability.type == CapabilityType.adjust) {
        return w.copyWith(value: v.toString());
      }
      if (w.device.id == deviceId && w.capability.type == CapabilityType.sensor) {
        return w.copyWith(value: v.toString());
      }
      return w;
    }).toList();

    emit(state.copyWith(widgets: updated, error: null));

    try {
      final w = updated.firstWhere((w) => w.widgetId == event.widgetId);
      await widgetRepo.sendWidgetCommand(
        widgetId: w.widgetId,
        capabilityId: w.capability.id,
        value: w.value,
      );
    } catch (e, st) {
      debugPrint('[DevicesBloc] adjust send failed: $e\n$st');
      emit(state.copyWith(widgets: before, error: _msgCommandFailed));
    }
  }

  void _onAllToggled(DevicesAllToggled event, Emitter<DevicesState> emit) {
    // ✅ ใช้ int แทน double
    final int turnOnValue = event.turnOn ? 1 : 0;

    final updated = state.widgets.map((w) {
      if (w.capability.type != CapabilityType.toggle) return w;
      return w.copyWith(value: turnOnValue.toString());
    }).toList();

    emit(state.copyWith(widgets: updated, error: null));
  }

  List<int> _currentVisibleIds(List<DeviceWidget> all) {
    final visible = all.where((w) => w.status != 'inactive').toList();
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
      // exit without saving: reset working to original
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

    final updatedWidgets = state.widgets.map((w) {
      final idx = orderIndex[w.widgetId];
      if (idx == null) return w;
      return w.copyWith(order: idx);
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));

    try {
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
        error: e.toString(), //
      ));
    }
  }


  String? _deviceIdOf(List<DeviceWidget> list, int widgetId) {
    final w = list.where((x) => x.widgetId == widgetId);
    if (w.isEmpty) return null;
    return w.first.device.id;
  }

  Future<void> _onDevicesRequested(
    DevicesRequested event,
    Emitter<DevicesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      // final devices = await deviceRepo.fetchDevices(
      //   connected: event.connectedOnly ? true : null,
      // );
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

      // ✅ refresh list
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

    // restart timer
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      print('Timer tick roomId=$_pollRoomId at ${DateTime.now()}');
      await _pollOnce();
    });
    print('Started polling widgets every ${_pollInterval.inSeconds} seconds for roomId=$_pollRoomId');
    // do an immediate fetch (so user doesn't wait for first tick)
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
      // ✅ ถ้า reorder อยู่ ให้ “skip” แต่ยังต้องปล่อยให้ finally ทำงานแน่นอน
      if (state.reorderEnabled || state.reorderSaving) {
        print('Polling skipped: reorderEnabled=${state.reorderEnabled} saving=${state.reorderSaving}');
        return;
      }

      final widgets = (_pollRoomId == null)
          ? await widgetRepo.fetchWidgets()
          : await roomRepo.fetchWidgetsByRoomId(_pollRoomId!);

      print('Polled widgets: ${widgets.length} items for roomId=$_pollRoomId');
      emit(state.copyWith(widgets: widgets, error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    } finally {
      _pollInFlight = false;
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _pollTimer = null;
    return super.close();
  }
}
