import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/device.dart';

class DeviceRepository {
  final String baseUrl;
  final http.Client _client;

  DeviceRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<List<Device>> fetchDevices({bool? connected}) async {
    // final uri = Uri.parse('$baseUrl/api/devices').replace(
    //   queryParameters: {
    //     if (connected != null) 'connected': connected.toString(), // true/false
    //   },
    // );
    final uri = Uri.parse('$baseUrl/api/devices');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load devices: ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);

    final List list = decoded is Map<String, dynamic>
        ? (decoded['data'] as List? ?? const [])
        : (decoded as List);

    return list
        .map((e) => Device.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> pairDevice({
    required String deviceId,
    required String deviceKey,
  }) async {
    final uri = Uri.parse('$baseUrl/api/devices/$deviceId/pair');

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'device_key': deviceKey,
      }),
    );
    print('pairDevice request: POST $uri with body ${jsonEncode({'device_key': deviceKey})}');
    print('pairDevice response: ${res.statusCode} ${res.body}');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to pair device: ${res.statusCode} ${res.body}');
    }
  }
}
