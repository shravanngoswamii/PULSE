import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';

class PulseApiClient {
  final Dio _dio;
  final bool mockMode;

  PulseApiClient({this.mockMode = true}) : _dio = Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = ApiConstants.requestTimeout;
    _dio.options.receiveTimeout = ApiConstants.requestTimeout;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  Dio get dio => _dio;
}

final apiClientProvider = Provider<PulseApiClient>((ref) {
  return PulseApiClient(mockMode: true);
});
