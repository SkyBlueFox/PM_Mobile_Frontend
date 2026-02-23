// lib/features/home/bloc/sensor_detail_bloc.dart
//
// ✅ FIX compile + ทำให้ heartbeat เสถียร
// - แก้ firstWhere(orElse: () => null) ที่ทำให้ error
// - เอา import device_repository ซ้ำออก
// - เอา extension แปลก ๆ (on Object? { get id => null; }) ออก
//
// แนวทาง heartbeat ที่ปลอดภัย:
// - fetchDevices() -> List<Device>
// - หา device ด้วยการวนลูปให้ได้ Device? (nullable) แล้วค่อยใช้
// - online priority: d.online (ถ้ามี) > เทียบเวลา lastHeartBeat กับ threshold

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/device_repository.dart';
import '../data/widget_repository.dart';

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
      // polling error: ไม่ทำให้หน้าพัง (ไม่ set error)
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _loadAll(Emitter<SensorDetailState> emit) async {
    // ถ้ายังไม่ได้ set widgetId/deviceId ก็ไม่ต้องยิง
    if (state.widgetId == 0) return;

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
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest first

    emit(state.copyWith(logs: sorted));
  }

  Future<void> _loadHeartbeat(Emitter<SensorDetailState> emit) async {
    final did = state.deviceId.trim();
    if (did.isEmpty) return;

    // deviceRepo.fetchDevices() ควร return List<Device>
    final devices = await deviceRepo.fetchDevices();

    // ✅ FIX: หาแบบ nullable โดยไม่ใช้ firstWhere(orElse: null)
    // ทำให้ไม่ error และอ่านง่าย/เสถียร
    dynamic found; // ใช้ dynamic ชั่วคราวถ้า model Device ของคุณยังไม่ถูก type ชัดในไฟล์นี้
    for (final d in devices) {
      // d ต้องมี field id เป็น String
      if (d.id == did) {
        found = d;
        break;
      }
    }
    if (found == null) return;

    final now = DateTime.now();

    // ต้องมี field:
    // - DateTime? lastHeartBeat
    // - bool? online
    final DateTime? last = found.lastHeartBeat;
    final bool? onlineFlag = found.online;

    final bool isOnline = onlineFlag ??
        (last != null ? now.difference(last).abs() <= onlineThreshold : false);

    emit(state.copyWith(
      lastHeartbeatAt: last,
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