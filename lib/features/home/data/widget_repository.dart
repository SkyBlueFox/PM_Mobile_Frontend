// lib/features/home/data/widget_repository.dart
//
// ✅ FIX: เพิ่มเมธอด saveRoomWidgetsVisibility()
// - ใช้ endpoint เดิม PATCH /api/widgets/{widgetId}/status
// - ทำ bulk ใน client: loop ทุก widgetId ในห้อง แล้ว set include/exclude ให้ตรงกับที่ผู้ใช้เลือก
//
// NOTE:
// - ถ้า backend มี bulk endpoint ในอนาคต เปลี่ยน implementation ในเมธอดนี้ได้เลย

import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:pm_mobile_frontend/features/auth/data/auth_api.dart';

import '../models/device_widget.dart';
import '../models/sensor_history.dart';
import '../models/sensor_log.dart';

class WidgetRepository {
  final String baseUrl;
  final http.Client _client;

  WidgetRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri _u(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  dynamic _decodeBody(http.Response res) {
    final body = res.body.trim();
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _extractListMap(dynamic decoded) {
    final dynamic raw = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
    final List list = raw is List ? raw : const [];
    return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  /// GET /api/widgets
  Future<List<DeviceWidget>> fetchWidgets() async {
    final uri = _u('/api/widgets');

    late final http.Response res;
    try {
      res = await _client.get(uri).timeout(const Duration(seconds: 15));
    } on SocketException catch (e) {
      throw Exception('Network error: $e');
    }

    if (res.statusCode != 200) {
      throw Exception('Failed to load widgets: ${res.statusCode}');
    }

    final decoded = _decodeBody(res);
    final maps = _extractListMap(decoded);
    return maps.map(DeviceWidget.fromJson).toList();
  }

  /// POST /api/widgets/{widgetId}/command
  Future<void> sendWidgetCommand({
    required int widgetId,
    required int capabilityId,
    required String value,
  }) async {
    final uri = _u('/api/widgets/$widgetId/command');
    final user = FirebaseAuth.instance.currentUser;
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'actor': user!.email,
            'value': value,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final decoded = _decodeBody(res);
      throw Exception('Failed to send command: ${res.statusCode} ${decoded ?? res.body}');
    }
  }

  /// PATCH /api/widgets/{widgetId}/status
  Future<void> changeWidgetStatus({
    required int widgetId,
    required String widgetStatus,
  }) async {
    final uri = _u('/api/widgets/$widgetId/status');

    final res = await _client
        .patch(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'widget_status': widgetStatus}),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final decoded = _decodeBody(res);
      throw Exception('Failed to change widget status: ${res.statusCode} ${decoded ?? res.body}');
    }
  }

  /// POST /api/rooms/{roomId}/widgets/order
  Future<void> changeWidgetsOrder({
    required int roomId,
    required List<int> widgetOrders,
  }) async {
    final uri = _u('/api/rooms/$roomId/widgets/order');

    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'widget_orders': widgetOrders}),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final decoded = _decodeBody(res);
      throw Exception('Failed to change widget order: ${res.statusCode} ${decoded ?? res.body}');
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ NEW: Save include/exclude ของทั้งห้อง (bulk)
  //
  // roomWidgetIds: widgetId ทั้งหมดในห้องนี้
  // includedWidgetIds: widgetId ที่ผู้ใช้เลือกให้ "Include"
  //
  // logic:
  // - ถ้าอยู่ใน included => 'include'
  // - ไม่อยู่ => 'exclude'
  // ---------------------------------------------------------------------------
  Future<void> saveRoomWidgetsVisibility({
    required List<int> roomWidgetIds,
    required List<int> includedWidgetIds,
  }) async {
    final includeSet = includedWidgetIds.toSet();

    // กันซ้ำ + ทำให้ลำดับ stable
    final all = roomWidgetIds.toSet().toList()..sort();

    for (final id in all) {
      final status = includeSet.contains(id) ? 'include' : 'exclude';
      await changeWidgetStatus(widgetId: id, widgetStatus: status);
    }
  }

  // ---------------------------------------------------------------------------
  // Sensor history
  // ---------------------------------------------------------------------------
  Future<List<SensorHistoryPoint>> fetchSensorHistory({
    required int widgetId,
    required DateTime from,
    required DateTime to,
    int limit = 500,
  }) async {
    Future<http.Response> _get(Uri uri) => _client.get(uri).timeout(const Duration(seconds: 15));

    final q = <String, String>{
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
      'limit': '$limit',
    };

    var uri = _u('/api/widgets/$widgetId/history', q);
    var res = await _get(uri);

    if (res.statusCode == 404) {
      uri = _u('/api/widgets/$widgetId/logs', q);
      res = await _get(uri);
    }

    if (res.statusCode != 200) {
      final decoded = _decodeBody(res);
      throw Exception('Failed to load sensor history: ${res.statusCode} ${decoded ?? res.body}');
    }

    final decoded = _decodeBody(res);
    final maps = _extractListMap(decoded);

    final points = maps.map(SensorHistoryPoint.fromJson).toList();
    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return points;
  }

  // ---------------------------------------------------------------------------
  // Sensor logs (ถ้าใช้ใน sensor detail)
  // ---------------------------------------------------------------------------
  Future<List<SensorLogEntry>> fetchSensorLogs({
    required int widgetId,
    required int limit,
  }) async {
    Future<http.Response> _get(Uri uri) => _client.get(uri).timeout(const Duration(seconds: 15));

    final q = <String, String>{'limit': '$limit'};

    final candidates = <String>[
      '/api/widgets/$widgetId/logs',
      '/api/widgets/$widgetId/log',
      '/api/widgets/$widgetId/events',
    ];

    http.Response? res;
    Uri? used;

    for (final path in candidates) {
      final uri = _u(path, q);
      final r = await _get(uri);
      if (r.statusCode != 404) {
        res = r;
        used = uri;
        break;
      }
    }

    if (res == null) {
      throw Exception('Failed to load sensor logs: endpoint not found (404)');
    }

    if (res.statusCode != 200) {
      final decoded = _decodeBody(res);
      throw Exception(
        'Failed to load sensor logs: ${res.statusCode} ${decoded ?? res.body} (uri=$used)',
      );
    }

    final decoded = _decodeBody(res);
    final maps = _extractListMap(decoded);

    final logs = maps.map(SensorLogEntry.fromJson).toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  void dispose() => _client.close();
}