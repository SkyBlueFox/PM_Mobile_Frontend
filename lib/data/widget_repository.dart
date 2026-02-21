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
  /// NOTE: backend บางครั้งคืน {"data":null} => ต้องแปลงเป็น [] เพื่อไม่พัง
  Future<List<DeviceWidget>> fetchWidgets() async {
    final res = await _client.get(Uri.parse('$baseUrl/api/widgets'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load widgets');
    }

    final decoded = jsonDecode(res.body);

    // supports:
    // { "data": [ ... ] } OR { "data": null } OR [ ... ]
    final List list = decoded is Map<String, dynamic>
        ? (decoded['data'] as List? ?? const [])
        : (decoded as List);

    return list
        .map((e) => DeviceWidget.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ส่งคำสั่งไป backend (toggle/adjust)
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
    print("Widget command sent: widgetId=$widgetId, capabilityId=$capabilityId, value=$value");
    print("Response status: ${res.statusCode}, body: ${res.body}");
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to send command');
    }
  }

  /// PATCH /api/widgets/{widget_id}/status
  Future<void> changeWidgetStatus({
    required int widgetId,
    required String widgetStatus, // 'active' | 'inactive'
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

  /// PATCH /api/widgets/order
  Future<void> changeWidgetsOrder(List<int> widgetOrders) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/api/widgets/order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'widget_orders': widgetOrders}),
    );
    print("widgetOrders sent to server: $widgetOrders");
    print("response status: ${res.statusCode}, body: ${res.body}");
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to change widget order');
    }
  }

  void dispose() => _client.close();
}
