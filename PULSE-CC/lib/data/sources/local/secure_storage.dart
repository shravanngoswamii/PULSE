import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage() : _storage = const FlutterSecureStorage();

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> saveToken(String token) async {
    await write('auth_token', token);
  }

  Future<String?> getToken() async {
    return await read('auth_token');
  }

  Future<void> deleteToken() async {
    await delete('auth_token');
  }

  Future<void> saveOfficerId(String id) async {
    await write('officer_id', id);
  }

  Future<String?> getOfficerId() async {
    return await read('officer_id');
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});
