// lib/features/auth/mnemonic_screen.dart

import 'package:digi_players/core/did/did_auth.dart';
import 'package:digi_players/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MnemonicScreen extends StatefulWidget {
  final List<String> mnemonic;
  const MnemonicScreen({super.key, required this.mnemonic});

  @override
  State<MnemonicScreen> createState() => _MnemonicScreenState();
}

class _MnemonicScreenState extends State<MnemonicScreen> {
  bool _confirmed = false;
  bool _isAuthenticating = false;

  /// 随机选 3 个位置让用户验证，防止跳过不看
  late final List<int> _quizIndices;
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // 随机选 3 个位置（0-indexed）
    final indices = List.generate(12, (i) => i)..shuffle();
    _quizIndices = indices.take(3).toList()..sort();
    for (final i in _quizIndices) {
      _controllers[i] = TextEditingController();
    }
    setState(() => _isAuthenticating = SecureStorage.isAuthenticating);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  bool _verifyInputs() {
    for (final i in _quizIndices) {
      final input = _controllers[i]!.text.trim().toLowerCase();
      if (input != widget.mnemonic[i].toLowerCase()) return false;
    }
    return true;
  }

  // 替换原来的 _onConfirm 方法

  Future<void> _onConfirm() async {
    if (!_verifyInputs()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('有单词不正确，请检查')));
      return;
    }

    // 显示 loading
    setState(() => _isAuthenticating = true);

    try {
      final result = await DIDAuth.authenticate();

      if (mounted) {
        // isNewUser == true 是首次注册，后期可跳新手引导
        context.go('/learn');
      }
    } on DioException catch (e) {
      if (mounted) {
        final data = e.response?.data;
        final msg = switch (data) {
          Map<String, dynamic>() => (data['error'] ?? data['message'])?.toString(),
          String() => data,
          _ => null,
        } ?? '网络错误，请重试';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('认证失败：$msg')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('错误：$e')));
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('备份助记词')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 警告说明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '请将以下 12 个单词按顺序抄写到纸上，并保存在安全的地方。'
                '这是恢复你账号的唯一方式，丢失后无法找回。',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 12 个助记词网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              itemCount: 12,
              itemBuilder: (context, i) => Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}. ${widget.mnemonic[i]}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 一键复制（方便测试，生产环境可考虑移除）
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: widget.mnemonic.join(' ')),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('复制助记词'),
            ),
            const SizedBox(height: 24),

            // 验证区
            Text(
              '验证：请填写以下位置的单词',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),

            for (final i in _quizIndices) ...[
              TextField(
                controller: _controllers[i],
                decoration: InputDecoration(
                  labelText: '第 ${i + 1} 个单词',
                  border: const OutlineInputBorder(),
                ),
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),
            FilledButton(
              onPressed: (_isAuthenticating) ? null : _onConfirm,
              child: _isAuthenticating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('我已抄写完毕，进入应用'),
            ),
          ],
        ),
      ),
    );
  }
}
