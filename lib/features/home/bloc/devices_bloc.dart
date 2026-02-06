import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/device_repository.dart';
import '../data/mqtt/mqtt_service.dart';
import '../data/mqtt/widget_update.dart';
import '../models/device.dart';
import '../models/device_widget.dart';
import '../models/capability.dart';
import '../models/room.dart';
import 'devices_event.dart';
import 'devices_state.dart';

class DevicesBloc extends Bloc<DeviceEvent, DevicesState> {
  StreamSubscription<WidgetUpdate>? _mqttSub;
  final DevicesRepository repo;

  DevicesBloc({
    required this.repo,
  }) : super(const DevicesState()) {
    on<DevicesStarted>(_onStarted);
    on<DevicesRoomChanged>(_onRoomChanged);
    on<WidgetToggled>(_onWidgetToggled);
    on<WidgetValueChanged>(_onWidgetValueChanged);
    on<DevicesAllToggled>(_onAllToggled);
    on<WidgetUpdateReceived>(_onWidgetUpdateReceived);
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
          value: 70,
        ),
        DeviceWidget(
          widgetId: 5,
          device: const Device(id: 70, name: 'speaker-01', type: 'speaker'),
          capability: const Capability(id: 3, type: CapabilityType.info),
          status: 'include',
          order: 3,
          value: 90,
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
        selectedRoomId: null,
        error: null,
      ));

      // ✅ Start MQTT realtime AFTER initial state is ready
      await _startMqttRealtime();
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'โหลดข้อมูลไม่สำเร็จ'));
    }
  }

  Future<void> _startMqttRealtime() async {
    await repo.connectRealtime();

    await _mqttSub?.cancel();
    _mqttSub = repo.realtimeUpdates().listen((u) {
      add(WidgetUpdateReceived(u.widgetId, u.value));
    });
  }

  void _onWidgetUpdateReceived(
    WidgetUpdateReceived event,
    Emitter<DevicesState> emit,
  ) {
    // Merge MQTT update into widgets list
    final updated = state.widgets.map((w) {
      if (w.widgetId != event.widgetId) return w;
      return w.copyWith(value: event.value);
    }).toList();

    emit(state.copyWith(widgets: updated));
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
  }

  void _onWidgetValueChanged(WidgetValueChanged event, Emitter<DevicesState> emit) {
    final deviceId = _deviceIdOf(event.widgetId);

    final updated = state.widgets.map((w) {
      if (w.device.id != deviceId) return w;

      if (w.widgetId == event.widgetId && w.capability.id == 2) {
        return w.copyWith(value: event.value);
      }

      if (w.capability.id == 3) {
        return w.copyWith(value: event.value);
      }

      return w;
    }).toList();

    emit(state.copyWith(widgets: updated));
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

  List<Device> _attachWidgetsToDevices(List<Device> devices, List<DeviceWidget> widgets) {
    final byDeviceId = <int, List<DeviceWidget>>{};
    for (final w in widgets) {
      byDeviceId.putIfAbsent(w.device.id, () => []).add(w);
    }

    return devices.map((d) {
      final ws = byDeviceId[d.id] ?? const <DeviceWidget>[];
      final sorted = [...ws]..sort((a, b) => a.order.compareTo(b.order));
      return d.copyWith(widgets: sorted);
    }).toList();
  }

  int _deviceIdOf(int widgetId) {
    return state.widgets.firstWhere((w) => w.widgetId == widgetId).device.id;
  }

  @override
  Future<void> close() async {
    await _mqttSub?.cancel();
    await repo.disconnectRealtime();
    return super.close();
  }
}
