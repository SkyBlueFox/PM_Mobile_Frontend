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

  static const Duration _timeout = Duration(seconds: 10);

  String _normalizeBaseUrl(String url) {
    // กัน baseUrl ลงท้ายด้วย / แล้วจะกลายเป็น //api/...
    if (url.endsWith('/')) return url.substring(0, url.length - 1);
    return url;
  }

  Uri _uri(String path) {
    final b = _normalizeBaseUrl(baseUrl);
    return Uri.parse('$b$path');
  }

  Map<String, String> get _jsonHeaders => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  /// GET /api/widgets
  /// NOTE: backend บางครั้งคืน {"data":null} => ต้องแปลงเป็น [] เพื่อไม่พัง
  /// NOTE: sort ตาม widgetId ให้เสมอ (UI/Bloc จะได้เชื่อถือ ordering ได้)
  Future<List<DeviceWidget>> fetchWidgets() async {
    final res = await _client
        .get(_uri('/api/widgets'), headers: const {'Accept': 'application/json'})
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Failed to load widgets: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    // supports:
    // { "data": [ ... ] } OR { "data": null } OR [ ... ]
    final List list = decoded is Map<String, dynamic>
        ? (decoded['data'] as List? ?? const [])
        : (decoded as List);

    final widgets = list
        .map((e) => DeviceWidget.fromJson(e as Map<String, dynamic>))
        .toList();

    // sort by widgetId (ascending)
    widgets.sort((a, b) => a.widgetId.compareTo(b.widgetId));

    return widgets;
  }

  /// POST /api/widgets/{widgetId}/command
  Future<void> sendWidgetCommand({
    required int widgetId,
    required int capabilityId,
    required String value,
  }) async {
    final res = await _client
        .post(
          _uri('/api/widgets/$widgetId/command'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'capability_id': capabilityId,
            'value': value,
          }),
        )
        .timeout(_timeout);

    // debug logs (คงไว้ตามของเดิม)
    print(
        "Widget command sent: widgetId=$widgetId, capabilityId=$capabilityId, value=$value");
    print("Response status: ${res.statusCode}, body: ${res.body}");

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to send command: ${res.statusCode} ${res.body}');
    }
  }

  /// PATCH /api/widgets/{widgetId}/status
  ///
  /// ใช้สำหรับ include/exclude ได้ ถ้า backend mapping ว่า:
  /// - include => 'active'
  /// - exclude => 'inactive'
  Future<void> changeWidgetStatus({
    required int widgetId,
    required String widgetStatus, // 'active' | 'inactive'
  }) async {
    final res = await _client
        .patch(
          _uri('/api/widgets/$widgetId/status'),
          headers: _jsonHeaders,
          body: jsonEncode({'widget_status': widgetStatus}),
        )
        .timeout(_timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'Failed to change widget status: ${res.statusCode} ${res.body}');
    }
  }

  /// บันทึก include/exclude แบบเป็นชุด โดยใช้ changeWidgetStatus ยิงทีละตัว
  /// (เหมาะกับกรณี backend ยังไม่มี bulk endpoint)
  ///
  /// ใช้จากหน้ากด "บันทึก" ใน widget picker:
  /// - widgets ต้องมี field ที่สะท้อนสถานะ include/exclude เช่น w.isActive หรือ w.status
  Future<void> saveWidgetSelectionByStatus({
    required List<DeviceWidget> widgets,
  }) async {
    // ยิงพร้อมกัน ช่วยลดเวลารวม (ถ้าอยาก throttle ค่อยปรับเป็น loop ทีละตัว)
    await Future.wait(
      widgets.map((w) {
        final status = 'active'; // Update this based on the actual field in DeviceWidget
        return changeWidgetStatus(widgetId: w.widgetId, widgetStatus: status);
      }),
    );
  }

  /// PATCH /api/widgets/order
  /// NOTE: ชื่อ method เดิมเป็น changeWidgetsOrder แต่ endpoint ในคอมเมนต์เดิมเป็น PATCH
  /// โค้ดเดิมใช้ PUT — คงไว้ตามเดิมเพื่อไม่ให้พังกับ backend ปัจจุบัน
  Future<void> changeWidgetsOrder(List<int> widgetOrders) async {
    final res = await _client
        .put(
          _uri('/api/widgets/order'),
          headers: _jsonHeaders,
          body: jsonEncode({'widget_orders': widgetOrders}),
        )
        .timeout(_timeout);

    print("widgetOrders sent to server: $widgetOrders");
    print("response status: ${res.statusCode}, body: ${res.body}");

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'Failed to change widget order: ${res.statusCode} ${res.body}');
    }
  }

  /// (ทางเลือก) ถ้า backend มี bulk endpoint จริงในอนาคต
  /// เช่น PUT /api/widgets/selection { included_widget_ids: [1,2,3] }
  /// ให้เปิดใช้เมธอดนี้แทน saveWidgetSelectionByStatus
  Future<void> saveWidgetSelectionBulk({
    required List<int> includedWidgetIds,
  }) async {
    final res = await _client
        .put(
          _uri('/api/widgets/selection'),
          headers: _jsonHeaders,
          body: jsonEncode({'included_widget_ids': includedWidgetIds}),
        )
        .timeout(_timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'Failed to save widget selection: ${res.statusCode} ${res.body}');
    }
  }

  void dispose() => _client.close();
}