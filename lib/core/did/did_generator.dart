// lib/core/did/did_generator.dart

import 'package:cryptography/cryptography.dart';
import 'package:bip39/bip39.dart' as bip39;
import '../crypto/base58.dart';
import 'did_key_pair.dart';

class DIDGenerator {
  static final _ed25519 = Ed25519();

  /// 生成全新的 DID 密钥对（首次注册使用）
  static Future<DIDKeyPair> generate() async {
    // 1. 生成 12 个助记词（128位熵）
    final mnemonicPhrase = bip39.generateMnemonic();
    final mnemonicWords = mnemonicPhrase.split(' ');

    // 2. 助记词 → 64字节种子（BIP-39 标准）
    final seedBytes = bip39.mnemonicToSeed(mnemonicPhrase);

    // 3. 取前32字节作为 Ed25519 私钥种子
    final privateKeySeed = seedBytes.sublist(0, 32);

    // 4. 生成 Ed25519 密钥对
    final keyPair = await _ed25519.newKeyPairFromSeed(privateKeySeed);
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = publicKey.bytes;

    // 5. 派生 did:key 地址
    //    格式：did:key:z + base58btc(multicodec前缀 + 公钥字节)
    //    Ed25519 multicodec 前缀：[0xed, 0x01]
    final multicodecKey = <int>[0xed, 0x01, ...publicKeyBytes];
    final did = 'did:key:z${base58Encode(multicodecKey)}';

    // 6. 提取私钥字节
    final privateKeyObj = await keyPair.extractPrivateKeyBytes();

    return DIDKeyPair(
      did: did,
      publicKeyBytes: publicKeyBytes,
      privateKeyBytes: privateKeyObj,
      mnemonic: mnemonicWords,
    );
  }

  /// 从助记词恢复 DID 密钥对（找回账号使用）
  static Future<DIDKeyPair> recover(String mnemonicPhrase) async {
    // 验证助记词合法性
    if (!bip39.validateMnemonic(mnemonicPhrase)) {
      throw ArgumentError('助记词无效，请检查单词拼写');
    }

    final mnemonicWords = mnemonicPhrase.trim().split(RegExp(r'\s+'));

    final seedBytes = bip39.mnemonicToSeed(mnemonicPhrase);
    final privateKeySeed = seedBytes.sublist(0, 32);

    final keyPair = await _ed25519.newKeyPairFromSeed(privateKeySeed);
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = publicKey.bytes;

    final multicodecKey = <int>[0xed, 0x01, ...publicKeyBytes];
    final did = 'did:key:z${base58Encode(multicodecKey)}';

    final privateKeyObj = await keyPair.extractPrivateKeyBytes();

    return DIDKeyPair(
      did: did,
      publicKeyBytes: publicKeyBytes,
      privateKeyBytes: privateKeyObj,
      mnemonic: mnemonicWords,
    );
  }

  /// 用私钥对消息签名（登录时用）
  static Future<List<int>> sign(
    List<int> privateKeyBytes,
    List<int> publicKeyBytes,
    String message,
  ) async {
    final keyPair = await _ed25519.newKeyPairFromSeed(privateKeyBytes);
    final signature = await _ed25519.sign(
      message.codeUnits,
      keyPair: keyPair,
    );
    return signature.bytes;
  }
}