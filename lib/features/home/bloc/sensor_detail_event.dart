// lib/features/home/bloc/sensor_detail_event.dart
//
// ✅ Event สำหรับหน้า Sensor Detail (คงเดิม ไม่กระทบส่วนอื่น)
// - เลือกช่วงเวลาใช้ SensorRangeChanged(from,to) ได้อยู่แล้ว
// - refresh manual + polling

sealed class SensorDetailEvent {
  const SensorDetailEvent();
}

/// โหลดครั้งแรก (history + log + heartbeat)
class SensorDetailStarted extends SensorDetailEvent {
  final int widgetId;
  final String deviceId;
  final String? unit;

  const SensorDetailStarted({
    required this.widgetId,
    required this.deviceId,
    this.unit,
  });
}

/// เปลี่ยนช่วงเวลา (กราฟ)
class SensorRangeChanged extends SensorDetailEvent {
  final DateTime from;
  final DateTime to;

  const SensorRangeChanged({
    required this.from,
    required this.to,
  });
}

/// refresh manual
class SensorDetailRefreshRequested extends SensorDetailEvent {
  const SensorDetailRefreshRequested();
}

/// เริ่ม polling
class SensorDetailPollingStarted extends SensorDetailEvent {
  final Duration interval;

  const SensorDetailPollingStarted({
    this.interval = const Duration(seconds: 5),
  });
}

/// หยุด polling
class SensorDetailPollingStopped extends SensorDetailEvent {
  const SensorDetailPollingStopped();
}