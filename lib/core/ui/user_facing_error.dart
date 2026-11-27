import 'package:dio/dio.dart';

/// 主流程给用户看的短句。不要把 Dio / 堆栈 / `error code:` 原文上屏。
abstract final class UserFacingError {
  static const network = '网络暂时不通，请稍后再试';
  static const service = '服务暂时不可用，请稍后再试';
  static const loadFailed = '暂时加载不了，请稍后再试';
  static const progressNotSaved = '没记上，请再试一次';
  static const deleteAccountFailed = '没删成，请检查网络后重试';
  static const chapterUnavailable = '章节暂时取不到';
  static const dailyQuizUnavailable = '今天的题暂时取不到';
  static const connectionFailed = '连不上，请检查网络后重试';
  static const sessionRefresh = '登录状态没能刷新，请检查网络后再试';

  /// 把异常收成短句；绝不返回 `DioException.toString()` 或边缘 `error code:`。
  static String from(Object? error, {String fallback = service}) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return network;
        case DioExceptionType.cancel:
          return fallback;
        case DioExceptionType.badCertificate:
        case DioExceptionType.badResponse:
        case DioExceptionType.unknown:
          break;
      }
      if (error.response?.statusCode == 401) return sessionRefresh;
      final raw = _rawBody(error.response?.data);
      if (raw != null && raw.contains('error code:')) return service;
      if (error.type == DioExceptionType.unknown && error.response == null) {
        return network;
      }
      return fallback;
    }
    return fallback;
  }

  static String? _rawBody(Object? data) {
    if (data is Map) {
      final value = data['error'] ?? data['message'];
      return value?.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}

/// 进度写入失败时的统一文案（历史调用方从 `progress_store` 导入）。
const progressNotSavedMessage = UserFacingError.progressNotSaved;
