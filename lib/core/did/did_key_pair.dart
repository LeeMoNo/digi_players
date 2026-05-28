// lib/core/did/did_key_pair.dart

class DIDKeyPair {
  /// did:key:z6Mk... 完整 DID 标识符
  final String did;

  /// 公钥原始字节（32字节，Ed25519）
  final List<int> publicKeyBytes;

  /// 私钥种子原始字节（32字节），只在内存中短暂存在
  /// 持久化时必须加密，见 SecureStorage
  final List<int> privateKeyBytes;

  /// 12个助记词（可恢复私钥）
  final List<String> mnemonic;

  const DIDKeyPair({
    required this.did,
    required this.publicKeyBytes,
    required this.privateKeyBytes,
    required this.mnemonic,
  });

  /// 助记词展示字符串（空格分隔）
  String get mnemonicPhrase => mnemonic.join(' ');

  /// DID 缩略展示（用于 UI）
  /// did:key:z6MkhaXgBZ...Vot → did:key:z6Mkh...Vot
  String get shortDID {
    if (did.length <= 20) return did;
    return '${did.substring(0, 16)}...${did.substring(did.length - 6)}';
  }
}