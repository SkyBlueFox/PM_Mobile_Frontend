import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/device_widget.dart';
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

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
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
    final raw = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
    final List list = raw is List ? raw : const [];
    return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<List<DeviceWidget>> fetchWidgets() async {
    final uri = _u('/api/widgets');

    final res = await _client
        .get(uri, headers: await _authHeaders())
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Failed to load widgets: ${res.statusCode}');
    }

    final decoded = _decodeBody(res);
    final maps = _extractListMap(decoded);
    return maps.map(DeviceWidget.fromJson).toList();
  }

  Future<void> sendWidgetCommand({
    required int widgetId,
    required int capabilityId,
    required String value,
  }) async {
    final uri = _u('/api/widgets/$widgetId/command');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final res = await _client.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({
        'actor': user.email,
        'value': value,
      }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final decoded = _decodeBody(res);
      throw Exception(
          'Failed to send command: ${res.statusCode} ${decoded ?? res.body}');
    }
  }

  Future<void> changeWidgetStatus({
    required int widgetId,
    required String widgetStatus,
  }) async {
    final uri = _u('/api/widgets/$widgetId/status');

    final res = await _client.patch(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({'widget_status': widgetStatus}),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final decoded = _decodeBody(res);
      throw Exception(
          'Failed to change widget status: ${res.statusCode} ${decoded ?? res.body}');
    }
  }

  Future<void> changeWidgetsOrder({
    required int roomId,
    required List<int> widgetOrders,
  }) async {
    final uri = _u('/api/rooms/$roomId/widgets/order');

    final res = await _client.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({'widget_orders': widgetOrders}),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final decoded = _decodeBody(res);
      throw Exception(
          'Failed to change widget order: ${res.statusCode} ${decoded ?? res.body}');
    }
  }

  Future<void> saveRoomWidgetsVisibility({
    required List<int> roomWidgetIds,
    required List<int> includedWidgetIds,
  }) async {
    final includeSet = includedWidgetIds.toSet();
    final all = roomWidgetIds.toSet().toList()..sort();

    for (final id in all) {
      final status = includeSet.contains(id) ? 'include' : 'exclude';
      await changeWidgetStatus(widgetId: id, widgetStatus: status);
    }
  }

  Future<List<SensorLogEntry>> fetchSensorLogs({
    required int widgetId,
    required String period, // hour | day | week
  }) async {
    Future<http.Response> _get(Uri uri) async {
      return await _client.get(
        uri,
        headers: await _authHeaders(),
      );
    }

    final q = {
      'period': period,
    };

    final uri = _u('/api/widgets/$widgetId/logs', q);
    final res = await _get(uri);

    if (res.statusCode != 200) {
      final decoded = _decodeBody(res);
      throw Exception(
        'Failed to load sensor logs: ${res.statusCode} ${decoded ?? res.body}',
      );
    }
  
    final decoded = _decodeBody(res);
    final maps = _extractListMap(decoded);

    final logs = maps.map(SensorLogEntry.fromJson).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return logs;
  }

  void dispose() => _client.close();
}