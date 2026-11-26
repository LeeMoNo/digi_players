// lib/features/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/did/did_generator.dart';
import '../../core/layout/reading_width.dart';
import '../../core/layout/window_layout.dart';
import '../../core/storage/secure_storage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isGenerating = false;

  Future<void> _onCreateIdentity() async {
    setState(() => _isGenerating = true);

    try {
      // 1. 生成 DID 密钥对（含助记词）
      final keyPair = await DIDGenerator.generate();

      // 2. 保存私钥到安全存储
      await SecureStorage.saveIdentity(
        privateKeyBytes: keyPair.privateKeyBytes,
        publicKeyBytes: keyPair.publicKeyBytes,
        did: keyPair.did,
      );

      // 在 saveIdentity 调用之后，跳转之前，追加这一行：
      await SecureStorage.saveMnemonic(keyPair.mnemonicPhrase);

      // 3. 跳转助记词界面（传递助记词，不传私钥）
      if (mounted) {
        context.push('/mnemonic', extra: keyPair.mnemonic);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('生成失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ReadingWidth(
          maxWidth: WindowLayout.formMaxWidth,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo 占位
                const Icon(Icons.fingerprint, size: 80),
                const SizedBox(height: 32),

                Text(
                  'DigiPlayers',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '你的身份由你掌控，不依赖任何服务器',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                FilledButton(
                  onPressed: _isGenerating ? null : _onCreateIdentity,
                  child: _isGenerating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('创建我的数字身份'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '创建即表示你同意',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/terms'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('《用户协议》'),
                    ),
                    Text(
                      '与',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/privacy'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('《隐私政策》'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                OutlinedButton(
                  onPressed: () => context.push('/recover'),
                  child: const Text('用助记词恢复'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
