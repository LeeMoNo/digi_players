// lib/core/crypto/base58.dart

const _alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

/// Base58btc 编码（did:key 标准使用）
String base58Encode(List<int> input) {
  if (input.isEmpty) return '';

  // 计算前置零字节数
  int leadingZeros = 0;
  for (final byte in input) {
    if (byte == 0) {
      leadingZeros++;
    } else {
      break;
    }
  }

  // 大整数转换
  final digits = <int>[0];
  for (final byte in input) {
    int carry = byte;
    for (int i = 0; i < digits.length; i++) {
      carry += digits[i] << 8;
      digits[i] = carry % 58;
      carry ~/= 58;
    }
    while (carry > 0) {
      digits.add(carry % 58);
      carry ~/= 58;
    }
  }

  final result = StringBuffer();
  for (int i = 0; i < leadingZeros; i++) {
    result.write(_alphabet[0]); // '1'
  }
  for (int i = digits.length - 1; i >= 0; i--) {
    result.write(_alphabet[digits[i]]);
  }

  return result.toString();
}