sealed class DeviceEvent {
  const DeviceEvent();
}

class DevicesStarted extends DeviceEvent {
  const DevicesStarted();
}

/// select a room (null = All)
class DevicesRoomChanged extends DeviceEvent {
  final int? roomId;
  const DevicesRoomChanged(this.roomId);
}

class WidgetToggled extends DeviceEvent {
  final int widgetId;
  const WidgetToggled(this.widgetId);
}

class WidgetValueChanged extends DeviceEvent {
  final int widgetId;
  final double value;
  const WidgetValueChanged(this.widgetId, this.value);
}

class DevicesAllToggled extends DeviceEvent {
  final bool turnOn;
  const DevicesAllToggled(this.turnOn);
}
