import 'package:dio/dio.dart';
import 'package:pulse_ev/config/env.dart';
import 'package:pulse_ev/core/storage/token_storage.dart';
import 'interceptors.dart';

class ApiClient {
  late final Dio dio;
  final TokenStorage? _tokenStorage;

  ApiClient({TokenStorage? tokenStorage}) : _tokenStorage = tokenStorage {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: Duration(milliseconds: Env.requestTimeout),
        receiveTimeout: Duration(milliseconds: Env.requestTimeout),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.addAll([
      LoggingInterceptor(),
      _AuthInterceptor(_tokenStorage),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return dio.post(path, data: data);
  }
}

class _AuthInterceptor extends Interceptor {
  final TokenStorage? _tokenStorage;

  _AuthInterceptor(this._tokenStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_tokenStorage != null) {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid - could trigger logout here
    }
    super.onError(err, handler);
  }
}
