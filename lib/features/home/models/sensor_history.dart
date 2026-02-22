// lib/features/home/models/sensor_history.dart
//
// Model สำหรับ “ข้อมูลกราฟ” ของ sensor
// จุดสำคัญ:
// - parse เวลาแบบปลอดภัย (รองรับทั้ง ISO string และ epoch ms/sec)
// - value อาจเป็น num/string/null => แปลงเป็น double? ให้ UI ใช้งานง่าย

class SensorHistoryPoint {
  /// เวลา ณ จุดนั้น (ใช้ plot บนแกน X)
  final DateTime timestamp;

  /// ค่าที่วัดได้ (ใช้ plot บนแกน Y)
  /// เป็น double เพื่อให้กราฟทำงานง่าย
  final double value;

  const SensorHistoryPoint({
    required this.timestamp,
    required this.value,
  });

  factory SensorHistoryPoint.fromJson(Map<String, dynamic> json) {
    final ts = _parseDateTime(json['timestamp'] ?? json['time'] ?? json['at']);
    final v = _parseDouble(json['value']);

    return SensorHistoryPoint(
      timestamp: ts ?? DateTime.fromMillisecondsSinceEpoch(0),
      value: v ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'value': value,
      };

  /// --- helpers (คอมเมนท์ไว้ให้แก้ตาม backend ได้ง่าย) ---

  /// รองรับ:
  /// - ISO string: "2026-02-22T10:00:00Z"
  /// - epoch ms: 1700000000000
  /// - epoch sec: 1700000000
  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;

    if (raw is DateTime) return raw;

    if (raw is num) {
      // heuristic: ถ้ามากกว่า 1e12 ถือว่าเป็น ms
      final n = raw.toInt();
      if (n > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true).toLocal();
      }
      // ไม่มาก -> สมมติเป็น seconds
      return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true).toLocal();
    }

    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    // ถ้าเป็นตัวเลขใน string
    final asNum = num.tryParse(s);
    if (asNum != null) return _parseDateTime(asNum);

    return DateTime.tryParse(s)?.toLocal();
  }

  static double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }
}