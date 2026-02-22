// lib/features/home/bloc/sensor_detail_event.dart

sealed class SensorDetailEvent {
  const SensorDetailEvent();
}

/// โหลดครั้งแรก (history + log + heartbeat)
class SensorDetailStarted extends SensorDetailEvent {
  final int widgetId;
  final String deviceId; // ✅ ใช้ lookup ใน DeviceRepository
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
  const SensorRangeChanged({required this.from, required this.to});
}

/// refresh ทันที
class SensorDetailRefreshRequested extends SensorDetailEvent {
  const SensorDetailRefreshRequested();
}

/// polling
class SensorDetailPollingStarted extends SensorDetailEvent {
  final Duration interval;
  const SensorDetailPollingStarted({this.interval = const Duration(seconds: 5)});
}

class SensorDetailPollingStopped extends SensorDetailEvent {
  const SensorDetailPollingStopped();
}