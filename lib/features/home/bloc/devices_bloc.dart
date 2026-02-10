import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/room_repository.dart';
import '../data/widget_repository.dart';
import '../models/capability.dart';
import 'devices_event.dart';
import 'devices_state.dart';

class DevicesBloc extends Bloc<DeviceEvent, DevicesState> {
  final WidgetRepository widgetRepo;
  final RoomRepository roomRepo;

  DevicesBloc({required this.widgetRepo, required this.roomRepo}) : super(const DevicesState()) {
    on<DevicesStarted>(_onStarted);
    on<DevicesRoomChanged>(_onRoomChanged);
    on<WidgetToggled>(_onWidgetToggled);
    on<WidgetValueChanged>(_onWidgetValueChanged);
    on<DevicesAllToggled>(_onAllToggled);
  }

  Future<void> _onStarted(DevicesStarted event, Emitter<DevicesState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // optional: load all include widgets (GET /api/widgets)
      final widgets = await widgetRepo.fetchWidgets();
      final rooms = await roomRepo.fetchRooms();


      emit(state.copyWith(
        isLoading: false,
        widgets: widgets,
        rooms: rooms,
        selectedRoomId: null,
        selectedRoomIdSet: true,
        error: null,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'โหลดข้อมูลไม่สำเร็จ'));
    }
  }

  Future<void> _onRoomChanged(
    DevicesRoomChanged event,
    Emitter<DevicesState> emit,
  ) async {
    // update selected tab immediately
    emit(state.copyWith(
      selectedRoomId: event.roomId,
      selectedRoomIdSet: true,
      isLoading: true,
      error: null,
    ));

    try {
      final int? roomId = event.roomId;

      // All tab -> load global widgets
      final widgets = roomId == null
          ? await widgetRepo.fetchWidgets()
          : await roomRepo.fetchWidgetsByRoomId(roomId);

      emit(state.copyWith(
        isLoading: false,
        widgets: widgets,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'โหลดข้อมูลไม่สำเร็จ: $e',
      ));
    }
  }

  Future<void> _onWidgetToggled(
    WidgetToggled event,
    Emitter<DevicesState> emit,
  ) async {
    final before = state.widgets;

    // optimistic update
    final updated = before.map((w) {
      if (w.widgetId != event.widgetId) return w;
      if (w.capability.id != 1) return w;

      final newValue = w.value >= 1 ? 0 : 1;
      return w.copyWith(value: newValue);
    }).toList();

    emit(state.copyWith(widgets: updated, error: null));

    try {
      final w = updated.firstWhere((x) => x.widgetId == event.widgetId);
      await widgetRepo.sendWidgetCommand(
        widgetId: w.widgetId,
        capabilityId: w.capability.type.toString(),
        value: w.value,
      );
    } catch (e) {
      // revert if API fails
      emit(state.copyWith(widgets: before, error: 'สั่งงานไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onWidgetValueChanged(
    WidgetValueChanged event,
    Emitter<DevicesState> emit,
  ) async {
    final before = state.widgets;

    // update UI
    final updated = state.widgets.map((w) {
      if (w.widgetId == event.widgetId && w.capability.id == 2) {
        return w.copyWith(value: event.value);
      }

      // info mirrors slider
      if (w.capability.id == 3) {
        // mirror only if same device as the adjust widget
        final deviceId = _deviceIdOf(event.widgetId);
        if (w.device.id == deviceId) return w.copyWith(value: event.value);
      }

      return w;
    }).toList();

    emit(state.copyWith(widgets: updated, error: null));

    // send command
    try {
      final w = state.widgets.firstWhere(
        (w) => w.widgetId == event.widgetId,
      );

      await widgetRepo.sendWidgetCommand(
        widgetId: event.widgetId,
        capabilityId: w.capability.type.toString(),
        value: event.value,
      );
    } catch (e) {
      // revert if API fails
      emit(state.copyWith(widgets: before, error: 'ปรับค่าไม่สำเร็จ: $e'));
    }
  }

  void _onAllToggled(DevicesAllToggled event, Emitter<DevicesState> emit) {
    final rid = state.selectedRoomId;
    final turnOnValue = event.turnOn ? 1 : 0;

    final updatedWidgets = state.widgets.map((w) {
      final inRoom = rid == null;
      if (!inRoom) return w;

      if (w.capability.type != CapabilityType.toggle) return w;
      return w.copyWith(value: turnOnValue);
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));
  }


  int _deviceIdOf(int widgetId) {
    return state.widgets.firstWhere((w) => w.widgetId == widgetId).device.id;
  }
}
