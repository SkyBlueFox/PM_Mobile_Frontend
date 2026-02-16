// lib/features/home/bloc/devices_event.dart
//
// Events for DevicesBloc.
// หลักการ: Event ต้องชื่อเดียวกับที่ Bloc ใช้ generics (DevicesEvent)
// เพื่อไม่ให้เกิด error แบบ "isn't a type".

sealed class DevicesEvent {
  const DevicesEvent();
}

/// initial load rooms + widgets (All)
class DevicesStarted extends DevicesEvent {
  const DevicesStarted();
}

/// select a room (null = All)
class DevicesRoomChanged extends DevicesEvent {
  final int? roomId;
  const DevicesRoomChanged(this.roomId);
}

/// toggle widget (capability = toggle)
class WidgetToggled extends DevicesEvent {
  final int widgetId;
  const WidgetToggled(this.widgetId);
}

/// slider/adjust change (capability = adjust)
class WidgetValueChanged extends DevicesEvent {
  final int widgetId;

  /// ใช้ double ภายใน state/repo (ปลอดภัยกว่า)
  /// UI ค่อย format เป็นจำนวนเต็มตอนแสดง
  final double value;

  const WidgetValueChanged(this.widgetId, this.value);
}

/// optional: toggle all in current room (ถ้าใช้)
class DevicesAllToggled extends DevicesEvent {
  final bool turnOn;
  const DevicesAllToggled(this.turnOn);
}

class ReorderModeChanged extends DevicesEvent {
  final bool enabled;
  const ReorderModeChanged(this.enabled);
}

class WidgetsOrderChanged extends DevicesEvent {
  final List<int> orderedWidgetIds;
  const WidgetsOrderChanged(this.orderedWidgetIds);
}

class CommitReorderPressed extends DevicesEvent {
  const CommitReorderPressed();
}

class DevicesRequested extends DevicesEvent {
  final bool connectedOnly;
  const DevicesRequested({this.connectedOnly = false});
}

class RoomCreateRequested extends DevicesEvent {
  final String roomName;
  const RoomCreateRequested(this.roomName);
}