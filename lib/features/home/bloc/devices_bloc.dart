import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_mobile_frontend/features/home/models/speaker_device.dart';

import '../models/device.dart';
import '../models/light_device.dart';
import 'devices_event.dart';
import 'devices_state.dart';

class DevicesBloc extends Bloc<DeviceEvent, DevicesState> {
  DevicesBloc() : super(const DevicesState()) {
    on<DevicesStarted>(_onStarted);
    on<DevicesTabChanged>(_onTabChanged);
    on<DevicesRoomChanged>(_onRoomChanged);
    on<DeviceToggled>(_onToggled);
    on<DeviceValueChanged>(_onValueChanged);
    on<DevicesAllToggled>(_onAllToggled);
  }

  Future<void> _onStarted(DevicesStarted event, Emitter<DevicesState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // ✅ ตอนนี้ mock เป็นไฟก่อน แต่ type เป็น Device ได้แล้ว
      final devices = <Device>[
        const LightDevice(id: 'l1', name: 'หลอดไฟ 1', room: RoomType.bedroom, isOn: true),
        const LightDevice(id: 'l2', name: 'หลอดไฟ 2', room: RoomType.bedroom, isOn: false),
        const SpeakerDevice(id: 's3', name: 'ลำโพง 1', room: RoomType.bedroom, isOn: true, value: 100),
        const SpeakerDevice(id: 's4', name: 'ลำโพง 2', room: RoomType.living,  isOn: false, value: 50),
      ];

      emit(state.copyWith(isLoading: false, devices: devices, error: null));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'โหลดข้อมูลไม่สำเร็จ'));
    }
  }

  void _onTabChanged(DevicesTabChanged event, Emitter<DevicesState> emit) {
    emit(state.copyWith(selectedTab: event.tab));
  }

  void _onRoomChanged(DevicesRoomChanged event, Emitter<DevicesState> emit) {
    emit(state.copyWith(selectedRoom: event.room));
  }

  void _onToggled(DeviceToggled event, Emitter<DevicesState> emit) {
    final idx = state.devices.indexWhere((d) => d.id == event.deviceId);
    if (idx < 0) return;

    final current = state.devices[idx];
    if (current is! Toggleable) return;

    final updated = [...state.devices];

    if (current is LightDevice) {
      updated[idx] = current.copyWith(isOn: !current.isOn);
    } else if (current is SpeakerDevice) {
      updated[idx] = current.copyWith(isOn: !current.isOn);
    } else {
      return;
    }

    emit(state.copyWith(devices: updated));
  }

  void _onValueChanged(DeviceValueChanged event, Emitter<DevicesState> emit) {
    final idx = state.devices.indexWhere((d) => d.id == event.deviceId);
    if (idx < 0) return;

    final device = state.devices[idx];
    if (device is! Quantifiable) return;

    final q = device as Quantifiable;
    final clamped = event.value.clamp(q.minValue, q.maxValue).toDouble();

    final updated = [...state.devices];

    if (device is SpeakerDevice) {
      updated[idx] = device.copyWith(value: clamped);
    } else {
      // LightDevice ตอนนี้เป็น toggle-only แล้ว จึงไม่ต้อง handle value
      // ถ้าคุณมี device แบบอื่นที่มี value ให้เพิ่ม else-if ที่นี่
      return;
    }

    emit(state.copyWith(devices: updated));
  }

  void _onAllToggled(DevicesAllToggled event, Emitter<DevicesState> emit) {
    // toggle เฉพาะตัวที่ "มองเห็นอยู่" (ตาม filter)
    final visibleIds = state.visibleDevices.map((d) => d.id).toSet();

    final updated = state.devices.map((d) {
      if (!visibleIds.contains(d.id)) return d;
      if (d is LightDevice) return d.copyWith(isOn: event.turnOn);
      return d;
    }).toList();

    emit(state.copyWith(devices: updated));
  }
}
