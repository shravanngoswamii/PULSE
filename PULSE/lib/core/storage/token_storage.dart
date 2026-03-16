import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/config/app_constants.dart';
import 'secure_storage.dart';

class TokenStorage {
  final SecureStorage _secureStorage;

  TokenStorage(this._secureStorage);

  Future<void> saveToken(String token) async {
    await _secureStorage.write(AppConstants.tokenKey, token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(AppConstants.tokenKey);
  }
}

// Providers
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return TokenStorage(secureStorage);
});
