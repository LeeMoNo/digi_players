import 'package:bip39/bip39.dart' as bip39;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/did/did_auth.dart';
import '../../core/did/did_generator.dart';
import '../../core/storage/secure_storage.dart';
import 'intro_screen.dart';

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _words(String raw) => raw
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onSubmit() async {
    if (_busy) return;

    final words = _words(_controller.text);
    if (words.length != 12) {
      _toast('请输入 12 个单词，用空格分开');
      return;
    }
    final phrase = words.join(' ');
    if (!bip39.validateMnemonic(phrase)) {
      _toast('助记词无效，请检查单词拼写');
      return;
    }

    setState(() => _busy = true);
    var saved = false;
    try {
      if (await SecureStorage.hasIdentity()) {
        if (!mounted) return;
        final replace = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('替换本机身份'),
            content: const Text('恢复会替换这台设备上的身份'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('继续恢复'),
              ),
            ],
          ),
        );
        if (replace != true) return;
      }

      final keyPair = await DIDGenerator.recover(phrase);
      await SecureStorage.saveIdentity(
        privateKeyBytes: keyPair.privateKeyBytes,
        publicKeyBytes: keyPair.publicKeyBytes,
        did: keyPair.did,
      );
      await SecureStorage.saveMnemonic(keyPair.mnemonicPhrase);
      saved = true;
      await SecureStorage.clearJWT();
      final result = await DIDAuth.authenticate();
      final route = await routeAfterAuth(result.isNewUser);
      if (!mounted) return;
      context.go(route);
    } on ArgumentError {
      _toast('助记词无效，请检查单词拼写');
    } on DioException {
      _toast('网络或服务暂时不可用。这组助记词已保存在本机，请稍后再试。');
    } catch (_) {
      _toast(
        saved
            ? '网络或服务暂时不可用。这组助记词已保存在本机，请稍后再试。'
            : '暂时无法完成恢复，请稍后再试。',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('恢复身份')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '输入当时抄下的 12 个单词，用空格分开。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              minLines: 3,
              maxLines: 5,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: '助记词',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _onSubmit(),
            ),
            const SizedBox(height: 12),
            Text(
              '单词数量不对或拼写错误时，会停在本页，不会改动这台设备上的身份。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _onSubmit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('恢复并进入'),
            ),
          ],
        ),
      ),
    );
  }
}
