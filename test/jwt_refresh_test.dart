import 'dart:convert';

import 'package:digi_players/core/did/did_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String tokenWithExp(int exp) {
    String part(String json) =>
        base64Url.encode(utf8.encode(json)).replaceAll('=', '');
    return '${part('{"alg":"none"}')}.${part('{"exp":$exp}')}.sig';
  }

  test('过期令牌需要重新签名', () {
    final expired = tokenWithExp(1);
    expect(jwtNeedsRefresh(expired, now: DateTime.utc(2026, 11, 24)), isTrue);
  });

  test('未过期令牌可以沿用', () {
    final future =
        DateTime.utc(2026, 11, 24, 12).millisecondsSinceEpoch ~/ 1000;
    final token = tokenWithExp(future);
    expect(
      jwtNeedsRefresh(token, now: DateTime.utc(2026, 11, 24, 10)),
      isFalse,
    );
    expect(jwtExpiry(token), DateTime.utc(2026, 11, 24, 12));
  });

  test('解析失败的令牌需要重新签名', () {
    expect(jwtNeedsRefresh('not-a-jwt'), isTrue);
    expect(jwtExpiry('a.b'), isNull);
  });
}
