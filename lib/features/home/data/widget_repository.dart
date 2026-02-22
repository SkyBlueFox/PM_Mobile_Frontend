import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/device_widget.dart';
import '../models/sensor_history.dart';

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
    // กัน response ว่าง/ไม่ใช่ json
    final body = res.body.trim();
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _extractListMap(dynamic decoded) {
    // supports:
    // { "data": [ ... ] } OR { "data": null } OR [ ... ] OR anything else -> []
    final dynamic raw = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
    final List list = raw is List ? raw : const [];

    return list
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
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

    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'actor': "test@gmail.com", //TODO: get from user.email
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
    required String widgetStatus, // 'include' | 'exclude'
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
  // ✅ FIX: เมธอดที่ bloc เรียกอยู่ (fetchSensorHistory) ต้องมีใน repo
  //
  // รูปแบบ query ที่รองรับ: from/to เป็น ISO8601
  // endpoint ที่พบบ่อย:
  //  - /api/widgets/{id}/history?from=...&to=...
  //  - /api/widgets/{id}/logs?from=...&to=...
  //
  // ถ้า backend ของคุณมีแค่อย่างเดียว ให้ลบอีกอันได้
  // ---------------------------------------------------------------------------
  Future<List<SensorHistoryPoint>> fetchSensorHistory({
    required int widgetId,
    required DateTime from,
    required DateTime to,
    int limit = 500,
  }) async {
    Future<http.Response> _get(Uri uri) =>
        _client.get(uri).timeout(const Duration(seconds: 15));

    final q = <String, String>{
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
      'limit': '$limit',
    };

    // ลอง /history ก่อน
    var uri = _u('/api/widgets/$widgetId/history', q);
    var res = await _get(uri);

    // ถ้า 404 ค่อย fallback ไป /logs
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

    // ให้ใช้ fromJson ของโมเดลจริงในโปรเจกต์คุณ
    final points = maps.map(SensorHistoryPoint.fromJson).toList();

    // กันข้อมูลสลับลำดับ
    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return points;
  }

  void dispose() => _client.close();

  fetchSensorLogs({required int widgetId, required int limit}) {}
}