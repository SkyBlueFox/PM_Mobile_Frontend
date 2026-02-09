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
      print('Room Fetching started...');
      final rooms = await roomRepo.fetchRooms();
      print('Rooms loaded: ${rooms.length}');

      final deviceRoomId = <int, int>{
        66: 1,
        67: 1,
        68: 2,
        70: 1,
      };

      emit(state.copyWith(
        isLoading: false,
        widgets: widgets,
        rooms: rooms,
        deviceRoomId: deviceRoomId,
        selectedRoomId: null,
        selectedRoomIdSet: true,
        error: null,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'โหลดข้อมูลไม่สำเร็จ'));
    }
  }

  void _onRoomChanged(DevicesRoomChanged event, Emitter<DevicesState> emit) {
    emit(state.copyWith(
      selectedRoomId: event.roomId,
      selectedRoomIdSet: true,
    ));
  }

  void _onWidgetToggled(WidgetToggled event, Emitter<DevicesState> emit) {
    final updated = state.widgets.map((w) {
      if (w.widgetId != event.widgetId) return w;
      if (w.capability.id != 1) return w;

      final newValue = w.value >= 1 ? 0.0 : 1.0;
      return w.copyWith(value: newValue);
    }).toList();

    emit(state.copyWith(widgets: updated));

    // OPTIONAL later: call backend
    // repo.setToggle(event.widgetId, newValue);
    // then refresh from backend if needed
  }

  void _onWidgetValueChanged(WidgetValueChanged event, Emitter<DevicesState> emit) {
    final deviceId = _deviceIdOf(event.widgetId);

    final updated = state.widgets.map((w) {
      if (w.device.id != deviceId) return w;

      if (w.widgetId == event.widgetId && w.capability.id == 2) {
        return w.copyWith(value: event.value);
      }

      // info mirrors slider (your rule)
      if (w.capability.id == 3) {
        return w.copyWith(value: event.value);
      }

      return w;
    }).toList();

    emit(state.copyWith(widgets: updated));

    // OPTIONAL later: call backend
    // repo.setAdjust(event.widgetId, event.value);
  }

  void _onAllToggled(DevicesAllToggled event, Emitter<DevicesState> emit) {
    final rid = state.selectedRoomId;
    final turnOnValue = event.turnOn ? 1.0 : 0.0;

    final updatedWidgets = state.widgets.map((w) {
      final inRoom = rid == null || state.deviceRoomId[w.device.id] == rid;
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
