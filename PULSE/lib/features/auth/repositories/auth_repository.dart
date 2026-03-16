import 'package:pulse_ev/core/storage/token_storage.dart';
import 'package:pulse_ev/features/auth/models/user_model.dart';
import 'package:pulse_ev/features/auth/services/auth_api_service.dart';

class AuthRepository {
  final AuthApiService _apiService;
  final TokenStorage _tokenStorage;

  AuthRepository(this._apiService, this._tokenStorage);

  Future<UserModel> login(String emailOrVehicleId, String password) async {
    final user = await _apiService.login(emailOrVehicleId, password);
    await _tokenStorage.saveToken(user.token);
    return user;
  }

  Future<UserModel> signup(String name, String email, String password) async {
    final user = await _apiService.signup(name, email, password);
    await _tokenStorage.saveToken(user.token);
    return user;
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _tokenStorage.deleteToken();
  }

  Future<String?> getSavedSession() async {
    return await _tokenStorage.getToken();
  }
}
