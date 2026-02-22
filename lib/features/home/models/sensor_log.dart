// lib/features/home/models/sensor_log.dart
//
// Model สำหรับ “Log ตาราง” ของ sensor
// จุดสำคัญ:
// - แยกจาก history เพราะ log มักมี field เพิ่ม เช่น unit/status/note
// - parse เวลา/ค่าแบบปลอดภัย

class SensorLogEntry {
  final DateTime timestamp;
  final String value; // เก็บเป็น string เพื่อแสดงผลตรง ๆ (เช่น "24.5", "ON", "cool")
  final String unit;  // optional

  const SensorLogEntry({
    required this.timestamp,
    required this.value,
    this.unit = '',
  });

  factory SensorLogEntry.fromJson(Map<String, dynamic> json) {
    final ts = _parseDateTime(json['timestamp'] ?? json['time'] ?? json['at']);
    final value = (json['value'] ?? '').toString();
    final unit = (json['unit'] ?? '').toString();

    return SensorLogEntry(
      timestamp: ts ?? DateTime.fromMillisecondsSinceEpoch(0),
      value: value,
      unit: unit,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'value': value,
        'unit': unit,
      };

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;

    if (raw is DateTime) return raw;

    if (raw is num) {
      final n = raw.toInt();
      if (n > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true).toLocal();
      }
      return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true).toLocal();
    }

    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    final asNum = num.tryParse(s);
    if (asNum != null) return _parseDateTime(asNum);

    return DateTime.tryParse(s)?.toLocal();
  }
}