import 'device_widget.dart';

class Device {
  final String id;
  final String name;
  final String type;
  final int? roomId;

  /// ✅ backend ส่งมาเป็น device_last_heartbeat (จากโค้ดคุณ)
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
    // ✅ กันชนิดแปลก/ค่าว่าง
    final roomRaw = json['room_id'];
    final hbRaw =
        json['device_last_heartbeat'] ?? json['last_heartbeat'] ?? json['heartbeat'];

    DateTime? hb;
    if (hbRaw is String && hbRaw.isNotEmpty) {
      hb = DateTime.tryParse(hbRaw);
    }

    return Device(
      id: (json['device_id'] ?? '').toString(),
      name: (json['device_name'] ?? '').toString(),
      type: (json['device_type'] ?? '').toString(),
      roomId: roomRaw == null ? null : (roomRaw as num).toInt(),
      lastHeartBeat: hb,
    );
  }

  get online => null;

  Map<String, dynamic> toJson() => {
        'device_id': id,
        'device_name': name,
        'device_type': type,
        'room_id': roomId,
        // ✅ ใช้ key ให้เข้ากับ backend ที่คุณ parse (device_last_heartbeat)
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