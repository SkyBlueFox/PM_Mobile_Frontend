class Device {
  final String id;
  final String name;
  final String type;

  /// ✅ backend ส่งมาเป็น device_last_heartbeat (จากโค้ดคุณ)
  final DateTime? lastHeartBeat;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.lastHeartBeat,
  });

  Device copyWith({
    String? id,
    String? name,
    String? type,
    DateTime? lastHeartBeat,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      lastHeartBeat: lastHeartBeat ?? this.lastHeartBeat,
    );
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    // รองรับทั้ง schema ใหม่ (id/name/type/lastHeartbeatAt)
    // และ schema เก่า (device_id/device_name/device_type/device_last_heartbeat)
    final id = json['device_id'].toString();
    final name = json['device_name'].toString();
    final type = json['device_type'].toString();
    final hbRaw = json['device_last_heartbeat'];
    DateTime? hb;
    if (hbRaw is String && hbRaw.isNotEmpty) {
      hb = DateTime.tryParse(hbRaw);
    }

    return Device(
      id: id,
      name: name,
      type: type,
      lastHeartBeat: hb,
    );
  }

  get online => null;

  Map<String, dynamic> toJson() => {
        'device_id': id,
        'device_name': name,
        'device_type': type,
        'device_last_heartbeat': lastHeartBeat?.toIso8601String(),
      };
}

class DevicesResponse {
  final List<Device> data;

  const DevicesResponse({required this.data});

  factory DevicesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final List list = raw is List ? raw : const [];
    return DevicesResponse(
      data: list
          .whereType<Map>()
          .map((e) => Device.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}