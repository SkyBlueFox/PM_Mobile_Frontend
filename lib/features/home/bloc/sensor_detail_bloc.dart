// lib/features/home/bloc/sensor_detail_bloc.dart
//
// เวอร์ชัน “มี DeviceRepository แล้ว”
// จุดที่ทำให้เสถียร:
// - polling กันซ้อนด้วย _inFlight
// - history/log: เรียกจาก WidgetRepository ที่เราเพิ่มเมธอดให้แล้ว
// - heartbeat: ใช้ DeviceRepository.fetchDevices() แล้วอ่าน Device.lastHeartBeat/online
// - sort กราฟตามเวลา และ log newest first

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_mobile_frontend/data/device_repository.dart';
import 'package:pm_mobile_frontend/features/home/data/widget_repository.dart';
import '../../../data/device_repository.dart';

import '../models/sensor_history.dart';
import '../models/sensor_log.dart';

import 'sensor_detail_event.dart';
import 'sensor_detail_state.dart';

class SensorDetailBloc extends Bloc<SensorDetailEvent, SensorDetailState> {
  final WidgetRepository widgetRepo;
  final DeviceRepository deviceRepo;

  Timer? _pollTimer;
  bool _inFlight = false;

  /// ถ้า heartbeat เก่ากว่า threshold -> offline
  final Duration onlineThreshold;

  SensorDetailBloc({
    required this.widgetRepo,
    required this.deviceRepo,
    this.onlineThreshold = const Duration(seconds: 15),
  }) : super(SensorDetailState.initial()) {
    on<SensorDetailStarted>(_onStarted);
    on<SensorRangeChanged>(_onRangeChanged);
    on<SensorDetailRefreshRequested>(_onRefreshRequested);
    on<SensorDetailPollingStarted>(_onPollingStarted);
    on<SensorDetailPollingStopped>(_onPollingStopped);
  }

  Future<void> _onStarted(SensorDetailStarted event, Emitter<SensorDetailState> emit) async {
    emit(state.copyWith(
      isLoading: true,
      error: null,
      widgetId: event.widgetId,
      deviceId: event.deviceId,
      unit: event.unit ?? state.unit,
    ));

    try {
      await _loadAll(emit);
      emit(state.copyWith(isLoading: false, error: null));
    } catch (e, st) {
      debugPrint('[SensorDetailBloc] start failed: $e\n$st');
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onRangeChanged(SensorRangeChanged event, Emitter<SensorDetailState> emit) async {
    emit(state.copyWith(from: event.from, to: event.to, isRefreshing: true, error: null));
    try {
      await _loadHistory(emit);
      emit(state.copyWith(isRefreshing: false, error: null));
    } catch (e, st) {
      debugPrint('[SensorDetailBloc] rangeChanged failed: $e\n$st');
      emit(state.copyWith(isRefreshing: false, error: e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    SensorDetailRefreshRequested event,
    Emitter<SensorDetailState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, error: null));
    try {
      await _loadAll(emit);
      emit(state.copyWith(isRefreshing: false, error: null));
    } catch (e, st) {
      debugPrint('[SensorDetailBloc] refresh failed: $e\n$st');
      emit(state.copyWith(isRefreshing: false, error: e.toString()));
    }
  }

  Future<void> _onPollingStarted(
    SensorDetailPollingStarted event,
    Emitter<SensorDetailState> emit,
  ) async {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(event.interval, (_) async {
      await _pollOnce(emit);
    });

    await _pollOnce(emit); // immediate
  }

  Future<void> _onPollingStopped(
    SensorDetailPollingStopped event,
    Emitter<SensorDetailState> emit,
  ) async {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce(Emitter<SensorDetailState> emit) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      await _loadAll(emit);
    } catch (_) {
      // polling error: ไม่ทำให้หน้าพัง
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _loadAll(Emitter<SensorDetailState> emit) async {
    await Future.wait([
      _loadHistory(emit),
      _loadLogs(emit),
      _loadHeartbeat(emit),
    ]);
  }

  Future<void> _loadHistory(Emitter<SensorDetailState> emit) async {
    final wid = state.widgetId;
    if (wid == 0) return;

    final List<SensorHistoryPoint> points = await widgetRepo.fetchSensorHistory(
      widgetId: wid,
      from: state.from,
      to: state.to,
    );

    final sorted = List<SensorHistoryPoint>.from(points)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final latest = sorted.isNotEmpty ? sorted.last.value : null;

    emit(state.copyWith(
      history: sorted,
      currentValue: latest == null ? state.currentValue : latest.toString(),
    ));
  }

  Future<void> _loadLogs(Emitter<SensorDetailState> emit) async {
    final wid = state.widgetId;
    if (wid == 0) return;

    final List<SensorLogEntry> logs = await widgetRepo.fetchSensorLogs(
      widgetId: wid,
      limit: 50,
    );

    final sorted = List<SensorLogEntry>.from(logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    emit(state.copyWith(logs: sorted));
  }

  Future<void> _loadHeartbeat(Emitter<SensorDetailState> emit) async {
    final did = state.deviceId.trim();
    if (did.isEmpty) return;

    final devices = await deviceRepo.fetchDevices();
    final match = devices.where((d) => d?.id == did).toList();
    if (match.isEmpty) return;

    final d = match.first;

    final last = d.lastHeartBeat;
    final onlineFlag = d.online;

    final now = DateTime.now();
    final isOnline = onlineFlag ??
        (last != null ? now.difference(last).abs() <= onlineThreshold : state.isOnline);

    emit(state.copyWith(
      lastHeartbeatAt: last ?? state.lastHeartbeatAt,
      isOnline: isOnline,
    ));
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _pollTimer = null;
    return super.close();
  }
}

extension on Object? {
  get id => null;
}