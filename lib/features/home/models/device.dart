import 'device_widget.dart';

class Device {
  final String id;
  final String name;
  final String type;
  final int? roomId;
  final DateTime? lastHeartBeat;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.roomId,
    required this.lastHeartBeat,
  });

  Device copyWith({
    String? id,
    String? name,
    String? type,
    int? roomId,
    DateTime? lastHeartBeat,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      lastHeartBeat: lastHeartBeat ?? this.lastHeartBeat,
    );
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    final roomRaw = json['room_id']; // can be null
    final hbRaw = json['device_last_heartbeat'];
    return Device(
      id: json['device_id'] as String,
      name: json['device_name'] as String,
      type: json['device_type'] as String,
      roomId: roomRaw == null ? null : (roomRaw as num).toInt(),
      lastHeartBeat: hbRaw == null ? null : DateTime.parse(hbRaw as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': id,
        'device_name': name,
        'device_type': type,
        'room_id': roomId,
        'last_heartbeat': lastHeartBeat?.toIso8601String(),
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
