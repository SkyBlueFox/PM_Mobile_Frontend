// lib/features/home/bloc/devices_bloc.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/room_repository.dart';
import '../data/widget_repository.dart';
import '../models/capability.dart';
import '../models/device_widget.dart';
import 'devices_event.dart';
import 'devices_state.dart';

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  final WidgetRepository widgetRepo;
  final RoomRepository roomRepo;

  static const String _msgLoadFailed = 'Unable to load data. Please try again.';
  static const String _msgCommandFailed = 'Unable to send command. Please try again.';

  DevicesBloc({
    required this.widgetRepo,
    required this.roomRepo,
  }) : super(const DevicesState()) {
    on<DevicesStarted>(_onStarted);
    on<DevicesRoomChanged>(_onRoomChanged);
    on<WidgetToggled>(_onWidgetToggled);
    on<WidgetValueChanged>(_onWidgetValueChanged);
    on<DevicesAllToggled>(_onAllToggled);
  }

  Future<void> _onStarted(DevicesStarted event, Emitter<DevicesState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final rooms = await roomRepo.fetchRooms();
      final widgets = await widgetRepo.fetchWidgets();

      emit(state.copyWith(
        isLoading: false,
        rooms: rooms,
        widgets: widgets,
        selectedRoomId: null,
        error: null,
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
    final before = state.widgets;

    final idx = before.indexWhere((w) => w.widgetId == event.widgetId);
    if (idx < 0) return;

    final target = before[idx];
    if (target.capability.type != CapabilityType.toggle) return;

    // ✅ ใช้ int แทน double
    final int newValue = target.value >= 1 ? 0 : 1;

    final updated = List<DeviceWidget>.from(before);
    updated[idx] = target.copyWith(value: newValue);

    emit(state.copyWith(widgets: updated, error: null));

    try {
      // TODO: ยิง API จริง
    } catch (e, st) {
      debugPrint('[DevicesBloc] toggle send failed: $e\n$st');
      emit(state.copyWith(widgets: before, error: _msgCommandFailed));
    }
  }

  Future<void> _onWidgetValueChanged(WidgetValueChanged event, Emitter<DevicesState> emit) async {
    final before = state.widgets;

    final deviceId = _deviceIdOf(before, event.widgetId);
    if (deviceId == null) return;

    // ✅ กันชนิดไม่ตรง: ถ้า event.value เป็น double ก็ปัดเป็น int ก่อน
    final int v = (event.value as num).round();

    final updated = before.map((w) {
      if (w.widgetId == event.widgetId && w.capability.type == CapabilityType.adjust) {
        return w.copyWith(value: v);
      }
      if (w.device.id == deviceId && w.capability.type == CapabilityType.info) {
        return w.copyWith(value: v);
      }
      return w;
    }).toList();

    emit(state.copyWith(widgets: updated, error: null));

    try {
      // TODO: ยิง API จริง
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
      return w.copyWith(value: turnOnValue);
    }).toList();

    emit(state.copyWith(widgets: updated, error: null));
  }

  int? _deviceIdOf(List<DeviceWidget> list, int widgetId) {
    final w = list.where((x) => x.widgetId == widgetId);
    if (w.isEmpty) return null;
    return w.first.device.id;
  }
}
