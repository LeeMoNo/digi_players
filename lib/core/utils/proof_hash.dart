// lib/core/utils/proof_hash.dart
import 'dart:convert';
import 'package:crypto/crypto.dart'; // pubspec 加：crypto: ^3.0.3

/// 生成游戏 proof_hash
/// raw = "did:action_key:seed:result_data"
String buildProofHash({
  required String did,
  required String actionKey,
  required String seed,
  required String resultData,
}) {
  final raw    = '$did:$actionKey:$seed:$resultData';
  final digest = sha256.convert(utf8.encode(raw));
  return digest.toString(); // 64位小写十六进制
}