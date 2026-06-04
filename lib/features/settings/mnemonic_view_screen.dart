// lib/features/settings/mnemonic_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/storage/secure_storage.dart';

class MnemonicViewScreen extends StatefulWidget {
  const MnemonicViewScreen({super.key});
  @override State<MnemonicViewScreen> createState() => _State();
}

class _State extends State<MnemonicViewScreen> {
  // 阶段：'verify'（身份验证） → 'show'（展示助记词）
  String _phase = 'verify';

  List<String> _mnemonic  = [];
  late List<int> _quizIdx; // 随机选的 2 个位置
  final Map<int, TextEditingController> _ctrls = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMnemonic();
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadMnemonic() async {
    final phrase = await SecureStorage.getMnemonic();
    if (phrase == null) return;
    final words = phrase.split(' ');

    // 随机选 2 个位置做验证
    final shuffled = List.generate(12, (i) => i)..shuffle();
    final indices  = (shuffled.take(2).toList()..sort());

    setState(() {
      _mnemonic = words;
      _quizIdx  = indices;
      for (final i in indices) _ctrls[i] = TextEditingController();
    });
  }

  void _verify() {
    for (final i in _quizIdx) {
      final input = _ctrls[i]!.text.trim().toLowerCase();
      if (input != _mnemonic[i].toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证失败，请检查单词是否正确')));
        return;
      }
    }
    setState(() => _phase = 'show');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('查看助记词')),
      body: _mnemonic.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _phase == 'verify'
              ? _buildVerify()
              : _buildShow(),
    );
  }

  Widget _buildVerify() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '助记词是你账户的唯一凭证，请确保周围没有他人。',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 28),
        const Text('为了确认是本人操作，\n请输入以下位置的助记词单词：',
            style: TextStyle(fontSize: 15, height: 1.6)),
        const SizedBox(height: 20),

        for (final i in _quizIdx) ...[
          TextField(
            controller: _ctrls[i],
            decoration: InputDecoration(
              labelText: '第 ${i + 1} 个单词',
              border: const OutlineInputBorder(),
            ),
            autocorrect:       false,
            enableSuggestions: false,
          ),
          const SizedBox(height: 14),
        ],

        const Spacer(),
        FilledButton(
          onPressed: _verify,
          child: const Text('确认身份'),
        ),
      ],
    ),
  );

  Widget _buildShow() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: const Text(
            '请勿截图或拍照！截图可能被其他应用读取。\n'
            '建议手抄后立即离开此页面。',
            style: TextStyle(fontSize: 13, color: Colors.red),
          ),
        ),
        const SizedBox(height: 20),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
          ),
          itemCount: 12,
          itemBuilder: (_, i) => Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}. ${_mnemonic[i]}',
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('复制到剪贴板'),
          onPressed: () {
            Clipboard.setData(
                ClipboardData(text: _mnemonic.join(' ')));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已复制，请尽快粘贴到安全的地方'),
                duration: Duration(seconds: 4),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          '离开此页面后，助记词不会再自动显示。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    ),
  );
}