import '../../../models/sensor_log.dart';

class SensorDetailState {
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  final int widgetId;
  final String deviceId;

  final String currentValue;
  final String unit;

  final List<SensorLogEntry> logs;
  final String period;

  final DateTime? lastHeartbeatAt;
  final bool isOnline;

  const SensorDetailState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.widgetId = 0,
    this.deviceId = '',
    this.currentValue = '',
    this.unit = '',
    this.logs = const [],
    this.period = '',
    this.lastHeartbeatAt,
    this.isOnline = false,
  });

  factory SensorDetailState.initial() {
    return SensorDetailState(
      period: 'hour'
    );
  }

  SensorDetailState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    int? widgetId,
    String? deviceId,
    String? currentValue,
    String? unit,
    List<SensorLogEntry>? logs,
    String? period,
    DateTime? lastHeartbeatAt,
    bool? isOnline,
    DateTime? from,
    DateTime? to,
  }) {
    return SensorDetailState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      widgetId: widgetId ?? this.widgetId,
      deviceId: deviceId ?? this.deviceId,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      logs: logs ?? this.logs,
      period: period ?? this.period,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}