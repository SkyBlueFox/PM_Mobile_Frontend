// devices_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/device.dart';
import '../models/device_widget.dart';
import '../models/capability.dart';
import '../models/room.dart';
import 'devices_event.dart';
import 'devices_state.dart';

class DevicesBloc extends Bloc<DeviceEvent, DevicesState> {
  DevicesBloc() : super(const DevicesState()) {
    on<DevicesStarted>(_onStarted);
    on<DevicesRoomChanged>(_onRoomChanged);
    on<WidgetToggled>(_onWidgetToggled);
    on<WidgetValueChanged>(_onWidgetValueChanged);
    on<DevicesAllToggled>(_onAllToggled);
  }

  Future<void> _onStarted(DevicesStarted event, Emitter<DevicesState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // MOCK: devices from /devices
      final devices = <Device>[
        const Device(id: 66, name: 'light-01', type: 'light'),
        const Device(id: 67, name: 'light-02', type: 'light'),
        const Device(id: 70, name: 'speaker-01', type: 'speaker'),
      ];

      // MOCK: widgets from /widgets
      final widgets = <DeviceWidget>[
        DeviceWidget(
          widgetId: 1,
          device: const Device(id: 66, name: 'light-01', type: 'light'),
          capability: const Capability(id: 1, type: CapabilityType.toggle),
          status: 'include',
          order: 1,
          value: 1,
        ),
        DeviceWidget(
          widgetId: 2,
          device: const Device(id: 67, name: 'light-02', type: 'light'),
          capability: const Capability(id: 1, type: CapabilityType.toggle),
          status: 'include',
          order: 1,
          value: 0,
        ),
        DeviceWidget(
          widgetId: 3,
          device: const Device(id: 70, name: 'speaker-01', type: 'speaker'),
          capability: const Capability(id: 1, type: CapabilityType.toggle),
          status: 'include',
          order: 1,
          value: 1,
        ),
        DeviceWidget(
          widgetId: 4,
          device: const Device(id: 70, name: 'speaker-01', type: 'speaker'),
          capability: const Capability(id: 2, type: CapabilityType.adjust),
          status: 'include',
          order: 2,
          value: 30,
        ),
      ];

      // MOCK: rooms from /rooms
      final rooms = <Room>[
        const Room(id: 1, name: 'ห้องนอน'),
        const Room(id: 2, name: 'ห้องนั่งเล่น'),
      ];

      // MOCK: mapping from room API (device_id -> room_id)
      final deviceRoomId = <int, int>{
        66: 1,
        67: 1,
        68: 2,
        70: 1,
      };

      final devicesWithWidgets = _attachWidgetsToDevices(devices, widgets);

      emit(state.copyWith(
        isLoading: false,
        devices: devicesWithWidgets,
        widgets: widgets,
        rooms: rooms,
        deviceRoomId: deviceRoomId,
        selectedRoomId: null, // default = All
        error: null,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'โหลดข้อมูลไม่สำเร็จ'));
    }
  }

  void _onRoomChanged(DevicesRoomChanged event, Emitter<DevicesState> emit) {
    if (event.roomId == null) {
      emit(state.copyWith(selectedRoomId: null, selectedRoomIdSet: true));
    } else {
      emit(state.copyWith(selectedRoomId: event.roomId, selectedRoomIdSet: true));
    }
  }

  void _onWidgetToggled(WidgetToggled event, Emitter<DevicesState> emit) {
    final updatedWidgets = state.widgets.map((w) {
      if (w.widgetId != event.widgetId) return w;
      if (w.capability.type != CapabilityType.toggle) return w;

      final newValue = w.value >= 1 ? 0.0 : 1.0;
      return w.copyWith(value: newValue);
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));
  }

  void _onWidgetValueChanged(WidgetValueChanged event, Emitter<DevicesState> emit) {
    final updatedWidgets = state.widgets.map((w) {
      if (w.widgetId != event.widgetId) return w;
      if (w.capability.type != CapabilityType.adjust) return w;

      return w.copyWith(value: event.value);
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));
  }

  void _onAllToggled(DevicesAllToggled event, Emitter<DevicesState> emit) {
    final rid = state.selectedRoomId;
    final turnOnValue = event.turnOn ? 1.0 : 0.0;

    final updatedWidgets = state.widgets.map((w) {
      // only affect widgets whose device is in current visible room
      final inRoom = rid == null || state.deviceRoomId[w.device.id] == rid;
      if (!inRoom) return w;

      if (w.capability.type != CapabilityType.toggle) return w;
      return w.copyWith(value: turnOnValue);
    }).toList();

    emit(state.copyWith(widgets: updatedWidgets));
  }

  List<Device> _attachWidgetsToDevices(List<Device> devices, List<DeviceWidget> widgets) {
    final byDeviceId = <int, List<DeviceWidget>>{};

    for (final w in widgets) {
      final did = w.device.id;
      byDeviceId.putIfAbsent(did, () => []).add(w);
    }

    return devices.map((d) {
      final ws = byDeviceId[d.id] ?? const <DeviceWidget>[];
      final sorted = [...ws]..sort((a, b) => a.order.compareTo(b.order));
      return d.copyWith(widgets: sorted);
    }).toList();
  }
}
