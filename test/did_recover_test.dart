import 'package:digi_players/core/did/did_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const phrase =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

  test('同一组助记词恢复出同一 DID', () async {
    final first = await DIDGenerator.recover(phrase);
    final second = await DIDGenerator.recover(
      '  Abandon   abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about ',
    );

    expect(second.did, first.did);
    expect(second.privateKeyBytes, first.privateKeyBytes);
    expect(first.did.startsWith('did:key:z'), isTrue);
  });

  test('刚生成的身份可以用助记词恢复成同一把钥匙', () async {
    final created = await DIDGenerator.generate();
    final restored = await DIDGenerator.recover(created.mnemonicPhrase);

    expect(restored.did, created.did);
    expect(restored.privateKeyBytes, created.privateKeyBytes);
    expect(restored.publicKeyBytes, created.publicKeyBytes);
  });

  test('词数不对或拼写错误时拒绝恢复', () {
    expect(
      () => DIDGenerator.recover(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon',
      ),
      throwsArgumentError,
    );
    expect(
      () => DIDGenerator.recover(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon',
      ),
      throwsArgumentError,
    );
  });
}
