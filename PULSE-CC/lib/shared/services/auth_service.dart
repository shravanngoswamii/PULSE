import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sources/local/secure_storage.dart';

class AuthService {
  final SecureStorage _storage;

  AuthService(this._storage);

  Future<bool> login(String authorityId, String password) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (authorityId.isNotEmpty && password.length >= 6) {
      await _storage.saveToken('mock_jwt_token_12345');
      await _storage.saveOfficerId(authorityId);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    await _storage.delete('officer_id');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null;
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthService(storage);
});
