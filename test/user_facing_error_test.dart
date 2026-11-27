import 'package:dio/dio.dart';
import 'package:digi_players/core/ui/user_facing_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('网络类 Dio 错误收成短句，不含堆栈', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/daily/quiz'),
      type: DioExceptionType.connectionError,
      message: 'SocketException: Failed host lookup',
    );
    final text = UserFacingError.from(error);
    expect(text, UserFacingError.network);
    expect(text.contains('SocketException'), isFalse);
    expect(text.contains('DioException'), isFalse);
  });

  test('边缘 error code 不上屏原文', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/auth'),
        statusCode: 500,
        data: 'error code: 1101',
      ),
    );
    final text = UserFacingError.from(error);
    expect(text, UserFacingError.service);
    expect(text.contains('error code:'), isFalse);
  });

  test('进度与删号短句保持稳定', () {
    expect(progressNotSavedMessage, '没记上，请再试一次');
    expect(UserFacingError.deleteAccountFailed, '没删成，请检查网络后重试');
    expect(UserFacingError.chapterUnavailable, '章节暂时取不到');
    expect(UserFacingError.dailyQuizUnavailable, '今天的题暂时取不到');
  });
}
