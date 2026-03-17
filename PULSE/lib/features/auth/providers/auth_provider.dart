import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/core/storage/token_storage.dart';
import 'package:pulse_ev/features/auth/repositories/auth_repository.dart';
import 'package:pulse_ev/features/auth/services/auth_api_service.dart';
import 'user_provider.dart';

// Service & Repository Providers
final authApiServiceProvider = Provider<AuthApiService>((ref) => AuthApiService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(authApiServiceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(apiService, tokenStorage);
});

// Auth State Notifier
enum AuthState { unauthenticated, loading, authenticated, error }

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;
  String? errorMessage;

  AuthNotifier(this._repository, this._ref) : super(AuthState.unauthenticated);

  Future<void> login(String emailOrVehicleId, String password) async {
    state = AuthState.loading;
    try {
      final user = await _repository.login(emailOrVehicleId, password);
      _ref.read(currentUserProvider.notifier).state = user;
      state = AuthState.authenticated;
    } catch (e) {
      errorMessage = e.toString();
      state = AuthState.error;
    }
  }

  Future<void> signup(String name, String email, String password) async {
    state = AuthState.loading;
    try {
      final user = await _repository.signup(name, email, password);
      _ref.read(currentUserProvider.notifier).state = user;
      state = AuthState.authenticated;
    } catch (e) {
      errorMessage = e.toString();
      state = AuthState.error;
    }
  }

  Future<void> logout() async {
    state = AuthState.loading;
    try {
      await _repository.logout();
      _ref.read(currentUserProvider.notifier).state = null;
      state = AuthState.unauthenticated;
    } catch (e) {
      errorMessage = e.toString();
      state = AuthState.error;
    }
  }

  Future<void> checkSession() async {
    try {
      final user = await _repository.validateSession();
      if (user != null) {
        _ref.read(currentUserProvider.notifier).state = user;
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }
    } catch (_) {
      state = AuthState.unauthenticated;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, ref);
});
