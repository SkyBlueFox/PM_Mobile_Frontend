import 'dart:convert';
import 'package:http/http.dart' as http;

import '../features/home/models/device_widget.dart';
import '../features/home/models/room.dart';
import '../features/home/models/device.dart';

class RoomRepository {
  final String baseUrl;
  final http.Client _client;

  RoomRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// GET /api/rooms
  Future<List<Room>> fetchRooms() async {
    final res = await _client.get(Uri.parse('$baseUrl/api/rooms'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load rooms');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final List list = body['data'] as List;

    return list
        .map(
          (e) => Room(
            id: e['room_id'] as int,
            name: e['room_name'] as String,
          ),
        )
        .toList();
  }

  Future<void> createRoom({
    required String roomName,
  }) async {
    final uri = Uri.parse('$baseUrl/api/rooms');

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'room_name': roomName,
      }),
    );
    print("response status: ${res.statusCode}, body: ${res.body}");
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to create room: ${res.statusCode} ${res.body}');
    }
  }

  /// GET /api/rooms/{room_id}/devices
  Future<List<Device>> fetchDevicesInRoom(int roomId) async {
    final res =
        await _client.get(Uri.parse('$baseUrl/api/rooms/$roomId/devices'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load devices for room $roomId');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final List list = body['data'] as List? ?? const [];
    return list
        .map(
          (e) => Device(
            id: e['device_id'] as String,
            name: e['device_name'] as String,
            type: e['device_type'] as String,
            roomId: roomId,                  //(e['room_id'] as num).toInt(),
            lastHeartBeat: DateTime.parse(e['device_last_heartbeat'] as String),
          ),
        )
        .toList();
  }

  Future<List<DeviceWidget>> fetchWidgetsByRoomId(int roomId) async {
    final res = await _client.get(Uri.parse('$baseUrl/api/rooms/$roomId/widgets'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load widgets for room $roomId');
    }

    final decoded = jsonDecode(res.body);

    // supports:
    // { "data": [ ... ] } OR [ ... ]
    final List list = decoded is Map<String, dynamic>
        ? (decoded['data'] as List? ?? const [])
        : (decoded as List);

    return list
        .map((e) => DeviceWidget.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addDeviceToRoom({
    required int roomId,
    required String deviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/rooms/$roomId/devices');

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'device_id': deviceId,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201 && res.statusCode != 204) {
      throw Exception(
        'Failed to add device to room: ${res.statusCode} ${res.body}',
      );
    }
  }

  /// ✅ PUT /api/rooms/{room_id}
  Future<void> updateRoom({
    required int roomId,
    required String roomName,
  }) async {
    final uri = Uri.parse('$baseUrl/api/rooms/$roomId');

    final res = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'room_name': roomName}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to update room: ${res.statusCode} ${res.body}');
    }
  }

  /// ✅ DELETE /api/rooms/{room_id}
  Future<void> deleteRoom({required int roomId}) async {
    final uri = Uri.parse('$baseUrl/api/rooms/$roomId');
    final res = await _client.delete(uri);

    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('Failed to delete room: ${res.statusCode} ${res.body}');
    }
  }

  void dispose() {
    _client.close();
  }
}
