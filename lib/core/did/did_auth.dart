import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'did_generator.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/totp_prompt.dart';

/// 令牌缺失、解析失败，或距离到期不足 [skew] 时需要重新签名。
bool jwtNeedsRefresh(
  String token, {
  DateTime? now,
  Duration skew = const Duration(seconds: 60),
}) {
  final exp = jwtExpiry(token);
  if (exp == null) return true;
  final current = now ?? DateTime.now().toUtc();
  return !exp.isAfter(current.toUtc().add(skew));
}

DateTime? jwtExpiry(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map) return null;
    final exp = payload['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  } catch (_) {
    return null;
  }
}

class DIDAuth {
  static final _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.workersBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static Future<({String jwt, bool isNewUser})>? _authInFlight;
  static Future<String>? _refreshInFlight;

  /// 完整认证流程：challenge → sign → verify → 保存 JWT。
  static Future<({String jwt, bool isNewUser})> authenticate() {
    final current = _authInFlight;
    if (current != null) return current;
    final run = _authenticate();
    _authInFlight = run;
    return run.whenComplete(() {
      if (identical(_authInFlight, run)) _authInFlight = null;
    });
  }

  static Future<({String jwt, bool isNewUser})> _authenticate() async {
    final did = await SecureStorage.getDID();
    if (did == null) throw Exception('DID not found, please register first');
    debugPrint('[身份] 开始签名 ${_shortDid(did)}');

    final challengeRes = await _dio.post('/auth/challenge', data: {'did': did});
    final nonce = challengeRes.data['nonce'] as String;

    final privateKeyBytes = await SecureStorage.getPrivateKeyBytes();
    final publicKeyBytes = await SecureStorage.getPublicKeyBytes();
    if (privateKeyBytes == null || publicKeyBytes == null) {
      throw Exception('Private key not found');
    }

    final signatureBytes = await DIDGenerator.sign(
      privateKeyBytes,
      publicKeyBytes,
      nonce,
    );
    final signatureB64 = base64Encode(signatureBytes);

    final verifyRes = await _dio.post(
      '/auth/verify',
      data: {'did': did, 'signature': signatureB64},
    );

    final data = verifyRes.data;
    if (data is Map && data['need_totp'] == true) {
      final ticket = data['totp_token'] as String?;
      if (ticket == null || ticket.isEmpty) {
        throw Exception('缺少二次验证票据');
      }
      debugPrint('[身份] 签名已通过，等待动态码');
      final jwt = await TotpPrompt.complete(ticket);
      if (jwt == null || jwt.isEmpty) throw Exception('已取消二次验证');
      await SecureStorage.saveJWT(jwt);
      final isNewUser = data['isNewUser'] == true;
      debugPrint('[身份] 二次验证通过 新用户=$isNewUser');
      return (jwt: jwt, isNewUser: isNewUser);
    }

    final jwt = data['jwt'] as String;
    final isNewUser = data['isNewUser'] as bool;
    await SecureStorage.saveJWT(jwt);
    debugPrint(
      '[身份] 签名成功 新用户=$isNewUser 令牌到期 ${_formatExpiry(jwtExpiry(jwt))}',
    );
    return (jwt: jwt, isNewUser: isNewUser);
  }

  /// 启动时使用。
  /// [interactive] 为 false 时（runApp 前）只沿用未过期令牌；过期就清掉，
  /// 等界面起来后再重新签名，避免二次验证弹窗没有地方显示。
  static Future<String?> ensureSession({bool interactive = true}) async {
    final existing = await SecureStorage.getJWT();
    if (existing != null && existing.isNotEmpty && !jwtNeedsRefresh(existing)) {
      debugPrint('[身份] 沿用未过期令牌，到期 ${_formatExpiry(jwtExpiry(existing))}');
      return existing;
    }
    if (!interactive) {
      if (existing != null && existing.isNotEmpty) {
        await SecureStorage.clearJWT();
        debugPrint('[身份] 启动时令牌已过期，先清掉，等界面起来再签名');
      } else {
        debugPrint('[身份] 启动时没有令牌，等界面起来后再签名');
      }
      return null;
    }
    debugPrint(
      existing == null || existing.isEmpty
          ? '[身份] 没有令牌，开始重新签名'
          : '[身份] 令牌已过期，丢掉后重新签名',
    );
    return refreshSession();
  }

  /// 服务端拒绝了当前令牌。先清掉再签名，避免把同一张过期令牌再发出去。
  static Future<String> refreshSession() {
    final current = _refreshInFlight;
    if (current != null) return current;
    final run = _refresh();
    _refreshInFlight = run;
    return run.whenComplete(() {
      if (identical(_refreshInFlight, run)) _refreshInFlight = null;
    });
  }

  static Future<String> _refresh() async {
    await SecureStorage.clearJWT();
    return (await authenticate()).jwt;
  }
}

String _shortDid(String did) {
  if (did.length <= 18) return did;
  return '${did.substring(0, 12)}…${did.substring(did.length - 4)}';
}

String _formatExpiry(DateTime? expiry) {
  if (expiry == null) return '未知';
  final local = expiry.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}
