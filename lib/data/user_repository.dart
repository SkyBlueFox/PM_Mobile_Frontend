// lib/features/Appuser/data/Appuser_reposotiry.dart
//
// จุดที่แก้เพื่อเสถียร:
// - ใช้รูปแบบเดียวกับ DeviceRepository
// - attach Firebase JWT ทุก request
// - parse response แบบกัน data:null / ไม่ใช่ list / ไม่ใช่ map
// - รองรับ status code หลายแบบที่ backend มักใช้

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';

class AppUserRepository {
  final String baseUrl;
  final http.Client _client;

  AppUserRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// 🔐 Attach Firebase JWT to every request
  Future<Map<String, String>> _authHeaders() async {
    final Appuser = FirebaseAuth.instance.currentUser;

    if (Appuser == null) {
      throw Exception('AppUser not authenticated');
    }

    final token = await Appuser.getIdToken();

    return {
      'Content-Type': 'lication/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// ✅ GET /api/users
  Future<List<AppUser>> fetchAppUsers() async {
    final uri = Uri.parse('$baseUrl/api/users');

    final res = await _client.get(
      uri,
      headers: await _authHeaders(),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load users (${res.statusCode}) ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    final dynamic raw =
        decoded is Map<String, dynamic> ? decoded['data'] : decoded;

    final List list = raw is List ? raw : const [];
    
    return list
        .whereType<Map<String, dynamic>>()
        .map(AppUser.fromJson)
        .toList(growable: false);
  }

  /// ✅ GET /api/Appusers/{user_id}
  Future<AppUser?> fetchAppUserById(int AppuserId) async {
    final uri = Uri.parse('$baseUrl/api/users/$AppuserId');

    final res = await _client.get(
      uri,
      headers: await _authHeaders(),
    );

    if (res.statusCode == 404) {
      return null;
    }

    if (res.statusCode != 200) {
      throw Exception('Failed to load Appuser (${res.statusCode}) ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    final dynamic raw =
        decoded is Map<String, dynamic> && decoded['data'] != null
            ? decoded['data']
            : decoded;

    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid Appuser response format');
    }

    return AppUser.fromJson(raw);
  }

  /// ✅ POST /api/users
  Future<AppUser> createAppUser({
    required String name,
    required String email,
  }) async {
    final uri = Uri.parse('$baseUrl/api/users');

    final res = await _client.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create Appuser (${res.statusCode}) ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    final dynamic raw =
        decoded is Map<String, dynamic> && decoded['data'] != null
            ? decoded['data']
            : decoded;

    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid create Appuser response format');
    }

    return AppUser.fromJson(raw);
  }

  /// ✅ DELETE /api/Appusers/{user_email}
  Future<void> deleteAppUser(String email) async {
    final uri = Uri.parse('$baseUrl/api/users/$email');

    final res = await _client.delete(
      uri,
      headers: await _authHeaders(),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete Appuser (${res.statusCode}) ${res.body}');
    }
  }

  void dispose() => _client.close();
}