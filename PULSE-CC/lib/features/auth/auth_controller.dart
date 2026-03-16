import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;
  final String? role;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
    this.role,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
    String? role,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AuthState());

  Future<bool> login(String authorityId, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final role = await _authService.login(authorityId, password);
      if (role != null) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          role: role,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid credentials. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Connection failed. Please check network.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService);
});
