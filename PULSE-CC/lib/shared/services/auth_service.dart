import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sources/local/secure_storage.dart';
import '../../data/sources/remote/pulse_api_client.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  final SecureStorage _storage;
  final PulseApiClient _apiClient;

  AuthService(this._storage, this._apiClient);

  /// Login with email/authorityId and password. Returns the user role from
  /// the backend JWT response, or null on failure.
  Future<String?> login(String authorityId, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'email': authorityId,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String? ?? data['token'] as String?;
        if (token != null) {
          await _storage.saveToken(token);
          await _storage.saveOfficerId(authorityId);

          // Extract role from response (may be nested under 'user')
          final user = data['user'] as Map<String, dynamic>?;
          final role = user?['role'] as String? ?? data['role'] as String?;
          if (role != null) {
            await _storage.write('user_role', role);
          }

          // Store user name and ID if present
          final name = user?['name'] as String? ?? data['name'] as String?;
          if (name != null) {
            await _storage.write('user_name', name);
          }
          final userId = user?['id'] as String? ?? data['id'] as String?;
          if (userId != null) {
            await _storage.write('user_id', userId);
          }

          return role ?? 'operator';
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.me);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    await _storage.delete('officer_id');
    await _storage.delete('user_role');
    await _storage.delete('user_name');
    await _storage.delete('user_id');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null;
  }

  Future<String?> getRole() async {
    return await _storage.read('user_role');
  }

  Future<String?> getUserName() async {
    return await _storage.read('user_name');
  }

  Future<String?> getUserId() async {
    return await _storage.read('user_id');
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(storage, apiClient);
});
