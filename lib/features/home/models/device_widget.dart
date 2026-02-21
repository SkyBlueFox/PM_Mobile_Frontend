import 'capability.dart';
import 'device.dart';

class DeviceWidget {
  final int widgetId;
  final Device device;
  final Capability capability;

  /// backend: 'active' | 'inactive' (หรือค่าที่เทียบได้)
  /// ใช้เป็น include/exclude
  final String status;

  final int order;

  /// backend บางทีอาจส่ง null / number => แปลงเป็น String เพื่อให้ UI ไม่พัง
  final String value;

  const DeviceWidget({
    required this.widgetId,
    required this.device,
    required this.capability,
    required this.status,
    required this.order,
    required this.value,
  });

  /// ใช้ใน UI/Bloc เพื่อเช็ค include/exclude แบบ boolean
  bool get included {
    final s = status.trim().toLowerCase();
    // ปรับ mapping ได้ตาม backend ของจริง
    return s == 'active' || s == 'include' || s == 'included' || s == 'enabled';
  }

  DeviceWidget copyWith({
    int? widgetId,
    Device? device,
    Capability? capability,
    String? status,
    int? order,
    String? value,
  }) {
    return DeviceWidget(
      widgetId: widgetId ?? this.widgetId,
      device: device ?? this.device,
      capability: capability ?? this.capability,
      status: status ?? this.status,
      order: order ?? this.order,
      value: value ?? this.value,
    );
  }

  /// ใช้เวลาจะ toggle include/exclude โดยยังคง field อื่นไว้
  DeviceWidget copyWithIncluded(bool included) {
    return copyWith(status: included ? 'active' : 'inactive');
  }

  factory DeviceWidget.fromJson(Map<String, dynamic> json) {
    final rawValue = json['value'];
    return DeviceWidget(
      widgetId: (json['widget_id'] as num).toInt(),
      device: Device.fromJson(json['device'] as Map<String, dynamic>),
      capability:
          Capability.fromJson(json['capability'] as Map<String, dynamic>),
      status: (json['widget_status'] ?? '').toString(),
      order: (json['widget_order'] as num?)?.toInt() ?? 0,
      value: rawValue == null ? '' : rawValue.toString(),
    );
  }

  /// ใช้ส่งกลับ backend ในบาง endpoint (เช่น order/selection)
  Map<String, dynamic> toJson() {
    return {
      'widget_id': widgetId,
      'widget_status': status,
      'widget_order': order,
      'value': value,
      'device': device.toJson?.call(), // ถ้า Device มี toJson เป็น method
      'capability': capability.toJson?.call(), // ถ้า Capability มี toJson
    }..removeWhere((k, v) => v == null);
  }
}

class WidgetsResponse {
  final List<DeviceWidget> data;

  const WidgetsResponse({required this.data});

  factory WidgetsResponse.fromJson(Map<String, dynamic> json) {
    // รองรับ {"data":null} ให้เป็น []
    final raw = json['data'];
    final list = (raw is List) ? raw : const [];

    return WidgetsResponse(
      data: list
          .whereType<Map<String, dynamic>>()
          .map(DeviceWidget.fromJson)
          .toList(),
    );
  }
}