// lib/core/storage/secure_storage.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Key 常量 ──────────────────────────────────
  static const _keyPrivateKey = 'dp_private_key';
  static const _keyPublicKey = 'dp_public_key';
  static const _keyDID = 'dp_did';
  static const _keyJWT = 'dp_jwt';

  // 同时在 State 类中添加状态变量
  static bool isAuthenticating = false;

  // ── DID 身份存取 ──────────────────────────────

  /// 保存完整身份（注册完成后调用一次）
  static Future<void> saveIdentity({
    required List<int> privateKeyBytes,
    required List<int> publicKeyBytes,
    required String did,
  }) async {
    await Future.wait([
      _storage.write(key: _keyPrivateKey, value: base64Encode(privateKeyBytes)),
      _storage.write(key: _keyPublicKey, value: base64Encode(publicKeyBytes)),
      _storage.write(key: _keyDID, value: did),
    ]);
  }

  /// 读取私钥字节（签名时调用，用完立刻丢弃）
  static Future<List<int>?> getPrivateKeyBytes() async {
    final encoded = await _storage.read(key: _keyPrivateKey);
    if (encoded == null) return null;
    return base64Decode(encoded);
  }

  /// 读取公钥字节
  static Future<List<int>?> getPublicKeyBytes() async {
    final encoded = await _storage.read(key: _keyPublicKey);
    if (encoded == null) return null;
    return base64Decode(encoded);
  }

  /// 读取 DID 标识符
  static Future<String?> getDID() async {
    return _storage.read(key: _keyDID);
  }

  /// 是否已注册（启动时检查）
  static Future<bool> hasIdentity() async {
    final did = await _storage.read(key: _keyDID);
    return did != null && did.isNotEmpty;
  }

  // ── JWT Session ───────────────────────────────

  static Future<void> saveJWT(String jwt) async {
    await _storage.write(key: _keyJWT, value: jwt);
  }

  static Future<String?> getJWT() async {
    return _storage.read(key: _keyJWT);
  }

  static Future<void> clearJWT() async {
    await _storage.delete(key: _keyJWT);
  }

  // ── 清除全部（慎用，等同注销） ─────────────────

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
