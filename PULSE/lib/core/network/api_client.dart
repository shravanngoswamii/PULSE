import 'package:dio/dio.dart';
import 'package:pulse_ev/config/env.dart';
import 'interceptors.dart';

class ApiClient {
  late final Dio dio;
  final bool mockMode;

  ApiClient({this.mockMode = false}) {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: Env.requestTimeout),
        receiveTimeout: const Duration(milliseconds: Env.requestTimeout),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.addAll([
      LoggingInterceptor(),
      // Add more interceptors like AuthInterceptor later
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return dio.post(path, data: data);
  }
}
