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

  Future<List<Device>> fetchDevices() async {
    final res = await _client.get(Uri.parse('$baseUrl/api/devices'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load devices');
    }

    final decoded = jsonDecode(res.body);

    final List list = decoded is Map<String, dynamic>
        ? (decoded['data'] as List? ?? const [])
        : (decoded as List);

    return list
        .map((e) => Device.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}