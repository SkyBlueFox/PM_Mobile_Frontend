import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/device_widget.dart';
import '../models/room.dart';
import '../models/device.dart';

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

  /// GET /api/rooms/{room_id}/devices
  Future<List<Device>> fetchDevicesInRoom(int roomId) async {
    final res =
        await _client.get(Uri.parse('$baseUrl/api/rooms/$roomId/devices'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load devices for room $roomId');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final List list = body['data'] as List;

    return list
        .map(
          (e) => Device(
            id: e['device_id'] as String,
            name: e['device_name'] as String,
            type: e['device_type'] as String,
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

  void dispose() {
    _client.close();
  }
}
