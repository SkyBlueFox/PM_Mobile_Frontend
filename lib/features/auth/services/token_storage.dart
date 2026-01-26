import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kAccessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  const TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _kAccessTokenKey, value: token);
  }

  Future<String?> readAccessToken() async {
    return _storage.read(key: _kAccessTokenKey);
  }

  Future<void> clearAccessToken() async {
    await _storage.delete(key: _kAccessTokenKey);
  }
}
