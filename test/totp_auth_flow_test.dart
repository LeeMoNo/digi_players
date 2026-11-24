import 'dart:convert';

import 'package:digi_players/core/did/did_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String tokenWithExp(int exp) {
    String part(String json) =>
        base64Url.encode(utf8.encode(json)).replaceAll('=', '');
    return '${part('{"alg":"none"}')}.${part('{"exp":$exp}')}.sig';
  }

  test('启动时 interactive=false 应对过期令牌走重新签名', () {
    final expired = tokenWithExp(1);
    expect(jwtNeedsRefresh(expired, now: DateTime.utc(2026, 11, 24)), isTrue);
  });

  test('未过期令牌在启动时可以继续用', () {
    final future =
        DateTime.utc(2026, 11, 24, 12).millisecondsSinceEpoch ~/ 1000;
    final token = tokenWithExp(future);
    expect(
      jwtNeedsRefresh(token, now: DateTime.utc(2026, 11, 24, 10)),
      isFalse,
    );
  });
}
