import 'capability.dart';
import 'device.dart';

class DeviceWidget {
  final int widgetId;
  final Device device;
  final Capability capability;

  final String status; // include / exclude
  final int order;
  final double value;

  const DeviceWidget({
    required this.widgetId,
    required this.device,
    required this.capability,
    required this.status,
    required this.order,
    required this.value,
  });

  bool get isIncluded => status == 'include';
  bool get isOn => capability.type == CapabilityType.toggle && value >= 1;

  DeviceWidget copyWith({
    int? widgetId,
    Device? device,
    Capability? capability,
    String? status,
    int? order,
    double? value,
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

  factory DeviceWidget.fromJson(Map<String, dynamic> json) {
    return DeviceWidget(
      widgetId: json['widget_id'] as int,
      device: Device.fromJson(json['device'] as Map<String, dynamic>),
      capability: Capability.fromJson(json['capability'] as Map<String, dynamic>),
      status: json['widget_status'] as String,
      order: json['widget_order'] as int,
      value: (json['widget_value'] as num).toDouble(),
    );
  }
}

class WidgetsResponse {
  final List<DeviceWidget> data;

  const WidgetsResponse({required this.data});

  factory WidgetsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List).cast<Map<String, dynamic>>();
    return WidgetsResponse(data: list.map(DeviceWidget.fromJson).toList());
  }
}
