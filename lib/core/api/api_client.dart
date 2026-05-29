import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static final Dio dio = Dio(BaseOptions(
    baseUrl: AppConfig.workersBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))..interceptors.add(_AuthInterceptor());
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final jwt = await SecureStorage.getJWT();
    if (jwt != null) options.headers['Authorization'] = 'Bearer $jwt';
    handler.next(options);
  }
}