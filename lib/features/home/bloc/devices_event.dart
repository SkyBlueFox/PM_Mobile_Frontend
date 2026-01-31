import '../models/device.dart';

sealed class DeviceEvent {
  const DeviceEvent();
}

class DevicesStarted extends DeviceEvent {
  const DevicesStarted();
}

class DevicesTabChanged extends DeviceEvent {
  final RoomType tab;
  const DevicesTabChanged(this.tab);
}

class DevicesRoomChanged extends DeviceEvent {
  final RoomType room;
  const DevicesRoomChanged(this.room);
}

/// toggle on/off
class DeviceToggled extends DeviceEvent {
  final String deviceId;
  const DeviceToggled(this.deviceId);
}

/// set value (brightness/speed/etc.)
class DeviceValueChanged extends DeviceEvent {
  final String deviceId;
  final double value;
  const DeviceValueChanged(this.deviceId, this.value);
}

/// toggle ทุกตัวที่อยู่ใน filter ปัจจุบัน (หรือจะทำเป็นทั้งห้องก็ได้)
class DevicesAllToggled extends DeviceEvent {
  final bool turnOn;
  const DevicesAllToggled(this.turnOn);
}
