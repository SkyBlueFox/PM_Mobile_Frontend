// lib/features/home/bloc/sensor_detail_state.dart

import '../models/sensor_history.dart';
import '../models/sensor_log.dart';

class SensorDetailState {
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  final int widgetId;
  final String deviceId;

  final String currentValue;
  final String unit;

  final List<SensorHistoryPoint> history;
  final List<SensorLogEntry> logs;

  final DateTime? lastHeartbeatAt;
  final bool isOnline;

  final DateTime from;
  final DateTime to;

  const SensorDetailState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.widgetId = 0,
    this.deviceId = '',
    this.currentValue = '',
    this.unit = '',
    this.history = const [],
    this.logs = const [],
    this.lastHeartbeatAt,
    this.isOnline = false,
    required this.from,
    required this.to,
  });

  factory SensorDetailState.initial() {
    final now = DateTime.now();
    return SensorDetailState(
      from: now.subtract(const Duration(hours: 24)),
      to: now,
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
    List<SensorHistoryPoint>? history,
    List<SensorLogEntry>? logs,
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
      history: history ?? this.history,
      logs: logs ?? this.logs,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      isOnline: isOnline ?? this.isOnline,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}