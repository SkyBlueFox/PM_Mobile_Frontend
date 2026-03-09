// lib/features/device/data/device_repository.dart
//
// จุดที่แก้เพื่อเสถียร:
// - import path ให้ถูก
// - ตัด print ที่ noisy ออก (ถ้าต้อง debug ค่อยเปิด)
// - parse response แบบกัน data:null / ไม่ใช่ list

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/device.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceRepository {
  final String baseUrl;
  final http.Client _client;

  DeviceRepository({
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

  /// ✅ GET /api/devices?connected=...
  Future<List<Device>> fetchDevices({bool? connected}) async {
    final uri = Uri.parse('$baseUrl/api/devices').replace(
      queryParameters: {
        if (connected != null) 'connected': connected.toString(),
      },
    );

    final res = await _client.get(
      uri,
      headers: await _authHeaders(),
    );

    if (res.statusCode != 200) {
      throw Exception(
          'Failed to load devices (${res.statusCode}) ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    final dynamic raw =
        decoded is Map<String, dynamic> ? decoded['data'] : decoded;

    final List list = raw is List ? raw : const [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(Device.fromJson)
        .toList(growable: false);
  }

  /// ✅ POST /api/devices/{device_id}/pair
  Future<void> pairDevice({
    required String deviceId,
    required String deviceKey,
  }) async {
    final uri = Uri.parse('$baseUrl/api/devices/$deviceId/pair');

    final res = await _client.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({
        'device_key': deviceKey,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
          'Failed to pair device (${res.statusCode}) ${res.body}');
    }
  }

  /// ✅ PUT /api/devices/{device_id}
  Future<void> updateDeviceName({
    required String deviceId,
    required String deviceName,
  }) async {
    final res = await _client.put(
      Uri.parse('$baseUrl/api/devices/$deviceId'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'device_name': deviceName,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(
          'Failed to update device name (${res.statusCode}) ${res.body}');
    }
  }

  /// ✅ POST /api/devices/{device_id}/unpair
  Future<void> unpairDevice(String deviceId) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/devices/$deviceId/unpair'),
      headers: await _authHeaders(),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
          'Failed to unpair device (${res.statusCode}) ${res.body}');
    }
  }

  void dispose() => _client.close();
}