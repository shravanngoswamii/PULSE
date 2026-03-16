import 'package:dio/dio.dart';
import 'package:pulse_ev/config/env.dart';
import 'package:pulse_ev/core/errors/api_exception.dart';
import 'package:pulse_ev/features/auth/models/user_model.dart';

class AuthApiService {
  final Dio _dio;

  AuthApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: Env.apiBaseUrl,
            connectTimeout: Duration(milliseconds: Env.requestTimeout),
            receiveTimeout: Duration(milliseconds: Env.requestTimeout),
            contentType: 'application/json',
          ),
        );

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data;
      final token = data['access_token'] as String? ?? data['token'] as String? ?? '';
      final user = data['user'] as Map<String, dynamic>? ?? data;
      return UserModel.fromJson({...user, 'token': token});
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Login failed';
      throw ApiException(
        message: message is String ? message : 'Login failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<UserModel> signup(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': 'driver',
        },
      );
      final data = response.data;
      final token = data['access_token'] as String? ?? data['token'] as String? ?? '';
      final user = data['user'] as Map<String, dynamic>? ?? data;
      return UserModel.fromJson({...user, 'token': token});
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Registration failed';
      throw ApiException(
        message: message is String ? message : 'Registration failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> logout() async {
    // No server-side logout needed for JWT; token is simply discarded
  }
}
