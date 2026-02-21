import 'capability.dart';
import 'device.dart';

class DeviceWidget {
  final int widgetId;
  final Device device;
  final Capability capability;

  /// backend: 'include' | 'exclude'
  final String status;

  final int order;

  /// backend อาจส่ง null/number => เก็บเป็น String เสมอ
  final String value;

  const DeviceWidget({
    required this.widgetId,
    required this.device,
    required this.capability,
    required this.status,
    required this.order,
    required this.value,
  });

  bool get included => status.trim().toLowerCase() == 'include';

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

  DeviceWidget copyWithIncluded(bool included) {
    return copyWith(status: included ? 'include' : 'exclude');
  }

  factory DeviceWidget.fromJson(Map<String, dynamic> json) {
    final rawValue = json['value'];

    return DeviceWidget(
      widgetId: (json['widget_id'] as num).toInt(),
      device: Device.fromJson(json['device'] as Map<String, dynamic>),
      capability: Capability.fromJson(json['capability'] as Map<String, dynamic>),
      status: (json['widget_status'] ?? 'exclude').toString(), // default exclude
      order: (json['widget_order'] as num?)?.toInt() ?? 0,
      value: rawValue == null ? '' : rawValue.toString(),
    );
  }
}

class WidgetsResponse {
  final List<DeviceWidget> data;

  const WidgetsResponse({required this.data});

  factory WidgetsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final list = (raw is List) ? raw : const [];

    return WidgetsResponse(
      data: list.whereType<Map<String, dynamic>>().map(DeviceWidget.fromJson).toList(),
    );
  }
}