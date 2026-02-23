// lib/features/home/models/sensor_log.dart
//
// ✅ FIX: ให้ UI เรียก e.title / e.detail / e.value / e.unit ได้
// - แก้ error ใน sensor_log_table.dart ที่เรียก e.unit
// - รองรับ backend หลายรูปแบบ (key ชื่อไม่เหมือนกัน)
// - เก็บ raw ไว้สำหรับ debug/ขยายในอนาคต

class SensorLogEntry {
  final DateTime timestamp;

  /// หัวข้อแถว log (เช่น "Temperature update", "Device reported", ...)
  final String title;

  /// รายละเอียดเพิ่มเติม (optional)
  final String detail;

  /// ค่า (optional) เก็บเป็น String? เพื่อ UI แสดงร่วมกับ unit ได้
  final String? value;

  /// ✅ NEW: หน่วย (optional) เผื่อ log ส่ง unit มาเอง
  /// ถ้า backend ไม่ส่ง จะเป็น '' แล้ว UI ค่อย fallback ไปใช้ unit ของ capability
  final String unit;

  /// เก็บ raw ไว้เผื่อ debug/ต่อยอด
  final Map<String, dynamic> raw;

  const SensorLogEntry({
    required this.timestamp,
    required this.title,
    required this.detail,
    required this.value,
    this.unit = '',
    this.raw = const {},
  });

  factory SensorLogEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseTime(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      final s = v.toString();
      final dt = DateTime.tryParse(s);
      return dt ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    // time keys ที่พบบ่อย
    final ts = parseTime(
      json['timestamp'] ??
          json['created_at'] ??
          json['time'] ??
          json['logged_at'] ??
          json['at'],
    );

    // title keys ที่พบบ่อย
    final title = (json['title'] ?? json['event'] ?? json['message'] ?? json['type'] ?? 'log').toString();

    // detail keys ที่พบบ่อย
    final detail = (json['detail'] ?? json['description'] ?? json['data'] ?? '').toString();

    // value keys ที่พบบ่อย (บางระบบส่ง number)
    final rawValue = json['value'] ?? json['val'] ?? json['v'];
    final value = rawValue == null ? null : rawValue.toString();

    // ✅ unit keys ที่พบบ่อย
    final unit = (json['unit'] ?? json['capability_unit'] ?? json['u'] ?? '').toString();

    return SensorLogEntry(
      timestamp: ts,
      title: title,
      detail: detail,
      value: value,
      unit: unit,
      raw: json,
    );
  }
}