import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

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

  /// 🔐 Attach Firebase JWT to every request
  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final token = await user.getIdToken(); // auto refresh if needed

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// ✅ GET /api/rooms
  Future<List<Room>> fetchRooms() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/rooms'),
      headers: await _authHeaders(),
    );

    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load rooms (${res.statusCode}) ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final List list = body['data'] as List? ?? const [];

    return list.map((e) {
      return Room(
        id: (e['room_id'] as num).toInt(),
        name: e['room_name'] as String,
      );
    }).toList();
  }

  /// ✅ POST /api/rooms
  Future<void> createRoom({
    required String roomName,
  }) async {
    final uri = Uri.parse('$baseUrl/api/rooms');

    final res = await _client.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({
        'room_name': roomName,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'Failed to create room (${res.statusCode}) ${res.body}');
    }
  }

  /// ✅ GET /api/rooms/{room_id}/devices
  Future<List<Device>> fetchDevicesInRoom(int roomId) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/rooms/$roomId/devices'),
      headers: await _authHeaders(),
    );

    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load devices ($roomId) ${res.statusCode} ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final List list = body['data'] as List? ?? const [];

    return list.map((e) {
      return Device(
        id: e['device_id'] as String,
        name: e['device_name'] as String,
        type: e['device_type'] as String,
        lastHeartBeat:
            DateTime.parse(e['device_last_heartbeat'] as String),
      );
    }).toList();
  }

  /// ✅ GET /api/rooms/{room_id}/widgets?status=...
  Future<List<DeviceWidget>> fetchWidgetsByRoomId(
      int roomId, String status) async {
    final uri = Uri.parse(
        '$baseUrl/api/rooms/$roomId/widgets?status=$status');

    final res = await _client.get(
      uri,
      headers: await _authHeaders(),
    );

    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load widgets ($roomId) ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    final List list = decoded is Map<String, dynamic>
        ? (decoded['data'] as List? ?? const [])
        : (decoded as List);

    return list
        .map((e) => DeviceWidget.fromJson(
              e as Map<String, dynamic>,
            ))
        .toList();
  }

  /// ✅ POST /api/rooms/{room_id}/devices
  Future<void> addDeviceToRoom({
    required int roomId,
    required String deviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/rooms/$roomId/devices');

    final res = await _client.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({
        'device_id': deviceId,
      }),
    );

    if (res.statusCode != 200 &&
        res.statusCode != 201 &&
        res.statusCode != 204) {
      throw Exception(
          'Failed to add device (${res.statusCode}) ${res.body}');
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
      headers: await _authHeaders(),
      body: jsonEncode({
        'room_name': roomName,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'Failed to update room (${res.statusCode}) ${res.body}');
    }
  }

  /// ✅ DELETE /api/rooms/{room_id}
  Future<void> deleteRoom({
    required int roomId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/rooms/$roomId');

    final res = await _client.delete(
      uri,
      headers: await _authHeaders(),
    );

    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(
          'Failed to delete room (${res.statusCode}) ${res.body}');
    }
  }

  void dispose() {
    _client.close();
  }
}