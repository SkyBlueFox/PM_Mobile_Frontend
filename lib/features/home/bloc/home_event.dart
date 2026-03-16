// lib/features/home/bloc/devices_event.dart
//
// ✅ devices_event.dart (ครบทั้งไฟล์)
// - รวม event เดิมทั้งหมด
// - ✅ เพิ่ม WidgetsVisibilitySaved สำหรับบันทึก include/exclude จาก widget picker (bulk)

sealed class HomeEvent {
  const HomeEvent();
}

/// initial load rooms + widgets (All)
class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// select a room (null = All)
class TabRoomChanged extends HomeEvent {
  final int roomId;
  const TabRoomChanged(this.roomId);
}

/// toggle widget (capability = toggle) = สั่งงานอุปกรณ์
class WidgetToggled extends HomeEvent {
  final int widgetId;
  const WidgetToggled(this.widgetId);
}

/// slider/adjust change (capability = adjust) = สั่งงานอุปกรณ์
class WidgetValueChanged extends HomeEvent {
  final int widgetId;
  final double value;
  const WidgetValueChanged(this.widgetId, this.value);
}

/// mode change (capability = mode) = สั่งงานอุปกรณ์
class WidgetModeChanged extends HomeEvent {
  final int widgetId;
  final String mode;
  const WidgetModeChanged(this.widgetId, this.mode);
}

/// text submit (capability = text) = ส่งข้อความไป device
class WidgetTextSubmitted extends HomeEvent {
  final int widgetId;
  final String text;
  const WidgetTextSubmitted(this.widgetId, this.text);
}

class WidgetButtonPressed extends HomeEvent {
  final int widgetId;

  final String value;
  const WidgetButtonPressed(this.widgetId, {this.value = 'press'});
}

// ------------------------------
// Reorder widgets
// ------------------------------
class ReorderModeChanged extends HomeEvent {
  final bool enabled;
  const ReorderModeChanged(this.enabled);
}

class WidgetsOrderChanged extends HomeEvent {
  final List<int> orderedWidgetIds;
  const WidgetsOrderChanged(this.orderedWidgetIds);
}

class CommitReorderPressed extends HomeEvent {
  const CommitReorderPressed();
}

// ------------------------------
// Devices list
// ------------------------------
class DevicesRequested extends HomeEvent {
  final bool? connected;
  const DevicesRequested({this.connected});
}

// ------------------------------
// Polling
// ------------------------------
class WidgetsPollingStarted extends HomeEvent {
  final int roomId;
  final Duration interval;
  const WidgetsPollingStarted({
    required this.roomId,
    this.interval = const Duration(seconds: 5),
  });
}

class WidgetsPollingStopped extends HomeEvent {
  const WidgetsPollingStopped();
}

/// ------------------------------
/// include/exclude selection (เดิม)
/// ------------------------------

/// โหลดรายการเพื่อทำ include/exclude (ใช้ก่อนเปิด picker)
class WidgetSelectionLoaded extends HomeEvent {
  final int roomId;
  const WidgetSelectionLoaded({required this.roomId});
}

/// toggle include/exclude (แสดง/ไม่แสดงบนหน้า Home) - ยิงทีละตัว
class WidgetIncludeToggled extends HomeEvent {
  final int widgetId;
  final bool included;
  const WidgetIncludeToggled({
    required this.widgetId,
    required this.included,
  });
}

/// กดบันทึก include/exclude (เดิม: ใช้ refresh หลังยิงทีละตัว)
class WidgetSelectionSaved extends HomeEvent {
  final int roomId;
  const WidgetSelectionSaved({required this.roomId});
}

/// ------------------------------
/// ✅ NEW: Save include/exclude จาก widget picker (bulk)
/// ------------------------------
class WidgetsVisibilitySaved extends HomeEvent {
  final int roomId;

  /// รายการ widgetId ที่ผู้ใช้เลือกให้ "Include"
  final List<int> includedWidgetIds;

  const WidgetsVisibilitySaved({
    required this.roomId,
    required this.includedWidgetIds,
  });
}