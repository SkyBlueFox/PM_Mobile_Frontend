// lib/features/home/data/widget_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../features/home/models/device_widget.dart';

class WidgetRepository {
  final String baseUrl;
  final http.Client _client;

  WidgetRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// GET /api/widgets
  /// NOTE: backend บางครั้งคืน {"data":null} หรือ data ไม่ใช่ list => ต้องแปลงเป็น [] เพื่อไม่พัง
  Future<List<DeviceWidget>> fetchWidgets() async {
    final res = await _client.get(Uri.parse('$baseUrl/api/widgets'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load widgets');
    }

    final decoded = jsonDecode(res.body);

    // supports:
    // { "data": [ ... ] } OR { "data": null } OR [ ... ] OR anything else -> []
    final dynamic raw = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
    final List list = raw is List ? raw : const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(DeviceWidget.fromJson)
        .toList();
  }

  /// ส่งคำสั่งไป backend (toggle/adjust/mode/text/button ใช้ endpoint เดียวกันได้)
  Future<void> sendWidgetCommand({
    required int widgetId,
    required int capabilityId,
    required String value,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/widgets/$widgetId/command'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'capability_id': capabilityId,
        'value': value,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to send command');
    }
  }

  /// PATCH /api/widgets/{widget_id}/status
  /// status: 'include' | 'exclude'
  Future<void> changeWidgetStatus({
    required int widgetId,
    required String widgetStatus, // 'include' | 'exclude'
  }) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/api/widgets/$widgetId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'widget_status': widgetStatus}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to change widget status');
    }
  }

  /// PUT /api/widgets/order
  /// ส่งเป็น "widget_ids ที่ include" เรียงตามลำดับใหม่
  Future<void> changeWidgetsOrder({
    required int roomId,
    required List<int> widgetOrders,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/rooms/$roomId/widgets/order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'widget_orders': widgetOrders}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to change widget order');
    }
  }

  void dispose() => _client.close();
}