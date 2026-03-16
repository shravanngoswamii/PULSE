import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../local/secure_storage.dart';

class PulseApiClient {
  final Dio _dio;
  final SecureStorage _storage;
  final bool mockMode;

  PulseApiClient({required SecureStorage storage, this.mockMode = false})
      : _storage = storage,
        _dio = Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = ApiConstants.requestTimeout;
    _dio.options.receiveTimeout = ApiConstants.requestTimeout;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Auth token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ));
  }

  Dio get dio => _dio;
}

final apiClientProvider = Provider<PulseApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return PulseApiClient(storage: storage, mockMode: false);
});
