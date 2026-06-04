import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../did/did_auth.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static final Dio dio = Dio(BaseOptions(
    baseUrl: AppConfig.workersBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))
    ..interceptors.add(_AuthInterceptor())
    ..interceptors.add(_UnauthorizedRetryInterceptor());
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final jwt = await SecureStorage.getJWT();
    if (jwt != null && jwt.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $jwt';
    }
    handler.next(options);
  }
}

/// 401 时用 DID 重新签名换取 JWT，并重试一次原请求
class _UnauthorizedRetryInterceptor extends Interceptor {
  static const _retryKey = 'auth_retried';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final retried = err.requestOptions.extra[_retryKey] == true;

    if (status != 401 || retried) {
      handler.next(err);
      return;
    }

    // 登录相关接口不要自动重试
    final path = err.requestOptions.path;
    if (path.startsWith('/auth/')) {
      handler.next(err);
      return;
    }

    try {
      await DIDAuth.ensureSession();
      final jwt = await SecureStorage.getJWT();
      if (jwt == null || jwt.isEmpty) {
        handler.next(err);
        return;
      }

      final opts = err.requestOptions;
      opts.extra[_retryKey] = true;
      opts.headers['Authorization'] = 'Bearer $jwt';

      final response = await ApiClient.dio.fetch(opts);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }
}
