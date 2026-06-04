// lib/core/did/did_auth.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'did_generator.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class DIDAuth {
  static final _dio = Dio(BaseOptions(
    baseUrl: AppConfig.workersBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// 完整认证流程：challenge → sign → verify → 保存 JWT
  /// 返回是否为新用户（用于决定展示欢迎流程还是直接进主页）
  static Future<({String jwt, bool isNewUser})> authenticate() async {
    final did = await SecureStorage.getDID();
    if (did == null) throw Exception('DID not found, please register first');

    // 1. 获取挑战码
    final challengeRes = await _dio.post(
      '/auth/challenge',
      data: {'did': did},
    );
    final nonce = challengeRes.data['nonce'] as String;

    // 2. 用本地私钥签名 nonce
    final privateKeyBytes = await SecureStorage.getPrivateKeyBytes();
    final publicKeyBytes  = await SecureStorage.getPublicKeyBytes();
    if (privateKeyBytes == null || publicKeyBytes == null) {
      throw Exception('Private key not found');
    }

    final signatureBytes = await DIDGenerator.sign(
      privateKeyBytes,
      publicKeyBytes,
      nonce,
    );

    // Workers 期望 standard base64（非 url-safe），atob 可直接处理
    final signatureB64 = base64Encode(signatureBytes);

    // 3. 提交签名，获取 JWT
    final verifyRes = await _dio.post(
      '/auth/verify',
      data: {'did': did, 'signature': signatureB64},
    );

    final jwt      = verifyRes.data['jwt']       as String;
    final isNewUser = verifyRes.data['isNewUser'] as bool;

    // 4. 保存 JWT
    await SecureStorage.saveJWT(jwt);

    return (jwt: jwt, isNewUser: isNewUser);
  }

  /// 确保本地有可用 JWT（启动时或 401 后调用）
  static Future<String> ensureSession() async {
    final existing = await SecureStorage.getJWT();
    if (existing != null && existing.isNotEmpty) return existing;
    return (await authenticate()).jwt;
  }
}