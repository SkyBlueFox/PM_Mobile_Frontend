class SensorLogEntry {
  final DateTime timestamp;
  final double value;

  const SensorLogEntry({
    required this.timestamp,
    required this.value,
  });

  factory SensorLogEntry.fromJson(Map<String, dynamic> json) {
    final ts = _parseDateTime(json['timestamp'] ?? json['time'] ?? json['at'] ?? json['created_at']);
    final v = _parseDouble(json['value']);

    return SensorLogEntry(
      timestamp: ts ?? DateTime.fromMillisecondsSinceEpoch(0),
      value: v ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'value': value,
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

  static double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }
}