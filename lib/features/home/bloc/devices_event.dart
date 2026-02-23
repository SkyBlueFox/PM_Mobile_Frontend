// lib/features/home/bloc/devices_event.dart
//
// ✅ devices_event.dart (ครบทั้งไฟล์)
// - รวม event เดิมทั้งหมด
// - ✅ เพิ่ม WidgetsVisibilitySaved สำหรับบันทึก include/exclude จาก widget picker (bulk)

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

/// toggle widget (capability = toggle) = สั่งงานอุปกรณ์
class WidgetToggled extends DevicesEvent {
  final int widgetId;
  const WidgetToggled(this.widgetId);
}

/// slider/adjust change (capability = adjust) = สั่งงานอุปกรณ์
class WidgetValueChanged extends DevicesEvent {
  final int widgetId;
  final double value;
  const WidgetValueChanged(this.widgetId, this.value);
}

/// mode change (capability = mode) = สั่งงานอุปกรณ์
class WidgetModeChanged extends DevicesEvent {
  final int widgetId;
  final String mode; // e.g. auto/cool/dry/fan/heat
  const WidgetModeChanged(this.widgetId, this.mode);
}

/// text submit (capability = text) = ส่งข้อความไป device
class WidgetTextSubmitted extends DevicesEvent {
  final int widgetId;
  final String text;
  const WidgetTextSubmitted(this.widgetId, this.text);
}

/// button press (capability = button) = กดครั้งเดียว (กริ่ง/trigger)
class WidgetButtonPressed extends DevicesEvent {
  final int widgetId;

  /// เผื่อ backend ต้องการค่าเฉพาะ (เช่น "press"/"1")
  final String value;
  const WidgetButtonPressed(this.widgetId, {this.value = 'press'});
}

/// optional: toggle all in current room (ถ้าใช้)
class DevicesAllToggled extends DevicesEvent {
  final bool turnOn;
  const DevicesAllToggled(this.turnOn);
}

// ------------------------------
// Reorder widgets
// ------------------------------
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

// ------------------------------
// Devices list
// ------------------------------
class DevicesRequested extends DevicesEvent {
  final bool connectedOnly;
  const DevicesRequested({this.connectedOnly = false});
}

// ------------------------------
// Polling
// ------------------------------
class WidgetsPollingStarted extends DevicesEvent {
  final int? roomId; // null = all
  final Duration interval;
  const WidgetsPollingStarted({
    this.roomId,
    this.interval = const Duration(seconds: 5),
  });
}

class WidgetsPollingStopped extends DevicesEvent {
  const WidgetsPollingStopped();
}

/// ------------------------------
/// include/exclude selection (เดิม)
/// ------------------------------

/// โหลดรายการเพื่อทำ include/exclude (ใช้ก่อนเปิด picker)
class WidgetSelectionLoaded extends DevicesEvent {
  final int? roomId;
  const WidgetSelectionLoaded({this.roomId});
}

/// toggle include/exclude (แสดง/ไม่แสดงบนหน้า Home) - ยิงทีละตัว
class WidgetIncludeToggled extends DevicesEvent {
  final int widgetId;
  final bool included;
  const WidgetIncludeToggled({
    required this.widgetId,
    required this.included,
  });
}

/// กดบันทึก include/exclude (เดิม: ใช้ refresh หลังยิงทีละตัว)
class WidgetSelectionSaved extends DevicesEvent {
  final int? roomId;
  const WidgetSelectionSaved({this.roomId});
}

/// ------------------------------
/// ✅ NEW: Save include/exclude จาก widget picker (bulk)
/// ------------------------------
class WidgetsVisibilitySaved extends DevicesEvent {
  final int? roomId;

  /// รายการ widgetId ที่ผู้ใช้เลือกให้ "Include"
  final List<int> includedWidgetIds;

  const WidgetsVisibilitySaved({
    this.roomId,
    required this.includedWidgetIds,
  });
}