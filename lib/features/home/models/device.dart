import 'device_widget.dart';

class Device {
  final String id;
  final String name;
  final String type;

  /// UI state only (widgets from /widgets endpoint)
  final List<DeviceWidget> widgets;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    this.widgets = const [],
  });

  Device copyWith({
    String? id,
    String? name,
    String? type,
    List<DeviceWidget>? widgets,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      widgets: widgets ?? this.widgets,
    );
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['device_id'] as String,
      name: json['device_name'] as String,
      type: json['device_type'] as String,
      // widgets are attached later
      widgets: const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': id,
        'device_name': name,
        'device_type': type,
      };
}

class DevicesResponse {
  final List<Device> data;

  const DevicesResponse({required this.data});

  factory DevicesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List).cast<Map<String, dynamic>>();
    return DevicesResponse(data: list.map(Device.fromJson).toList());
  }
}
