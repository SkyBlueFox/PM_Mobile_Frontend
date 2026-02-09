import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/device_widget.dart';

class WidgetRepository {
  final String baseUrl;
  final http.Client _client;

  WidgetRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// GET /api/widgets
  /// get all include widgets
  Future<List<DeviceWidget>> fetchWidgets() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/widgets'),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load widgets');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final List list = decoded['data'] as List;

    return list
        .map((e) => DeviceWidget.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/widgets/{widget_id}
  Future<DeviceWidget> fetchWidgetById(int widgetId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/widgets/$widgetId'),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load widget $widgetId');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return DeviceWidget.fromJson(decoded);
  }

  /// POST /api/widget
  Future<void> createWidget({
    required int deviceId,
    required int capabilityId,
    required String widgetStatus,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/widget'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_id': deviceId,
        'capability_id': capabilityId,
        'widget_status': widgetStatus,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to create widget');
    }
  }

  Future<void> sendWidgetCommand({
    required int widgetId,
    required String capabilityId,
    required int value,
  }) async {
    final url = Uri.parse('$baseUrl/api/widgets/$widgetId/command');

    final res = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'capability_id': capabilityId,
        'value': value,
      }),
    );
    if (res.statusCode != 202) {
      throw Exception(
        'Command failed (id=$widgetId, status=${res.statusCode}, body=${res.body})',
      );
    }
  }


  /// PUT /api/widgets/{widget_id}
  Future<void> updateWidget({
    required int widgetId,
    required int deviceId,
    required int capabilityId,
    required String widgetStatus,
  }) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/api/widgets/$widgetId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_id': deviceId,
        'capability_id': capabilityId,
        'widget_status': widgetStatus,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update widget $widgetId');
    }
  }

  /// PATCH /api/widgets/{widget_id}/status
  Future<void> changeWidgetStatus({
    required int widgetId,
    required String widgetStatus,
  }) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/api/widgets/$widgetId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'widget_status': widgetStatus,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to change widget status');
    }
  }

  /// PATCH /api/widgets/order
  Future<void> changeWidgetsOrder(List<int> widgetOrders) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/api/widgets/order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'widget_orders': widgetOrders,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to change widget order');
    }
  }

  /// DELETE /api/widgets/{widget_id}
  Future<void> deleteWidget(int widgetId) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl/api/widgets/$widgetId'),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to delete widget $widgetId');
    }
  }

  void dispose() {
    _client.close();
  }
}
