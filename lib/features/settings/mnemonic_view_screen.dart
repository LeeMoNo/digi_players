// lib/features/settings/mnemonic_view_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/layout/reading_width.dart';
import '../../core/router/app_back_button.dart';
import '../../core/layout/window_layout.dart';
import '../../core/storage/secure_storage.dart';

class MnemonicViewScreen extends StatefulWidget {
  const MnemonicViewScreen({super.key});
  @override
  State<MnemonicViewScreen> createState() => _State();
}

class _State extends State<MnemonicViewScreen> {
  // 阶段：totp（动态码） → verify（单词） → show
  String _phase = 'verify';
  var _totpOn = false;
  final _totpCode = TextEditingController();
  var _checkingTotp = false;

  List<String> _mnemonic = [];
  List<int> _quizIdx = [];
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
    _totpCode.dispose();
    super.dispose();
  }

  Future<void> _loadMnemonic() async {
    final phrase = await SecureStorage.getMnemonic();
    if (phrase == null) return;
    var totpOn = false;
    try {
      final res = await ApiClient.dio.get('/user/profile');
      final data = res.data;
      totpOn = data is Map && data['totp_enabled'] == true;
    } catch (_) {}
    final words = phrase.split(' ');

    final shuffled = List.generate(12, (i) => i)..shuffle();
    final indices = (shuffled.take(2).toList()..sort());

    if (!mounted) return;
    setState(() {
      _mnemonic = words;
      _totpOn = totpOn;
      _phase = totpOn ? 'totp' : 'verify';
      _quizIdx = indices;
      for (final i in indices) {
        _ctrls[i] = TextEditingController();
      }
    });
  }

  Future<void> _checkTotp() async {
    final code = _totpCode.text.trim();
    if (code.isEmpty || _checkingTotp) return;
    setState(() => _checkingTotp = true);
    try {
      await ApiClient.dio.post('/user/totp/check', data: {'code': code});
      if (!mounted) return;
      setState(() => _phase = 'show');
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final message = status == 429 ? '试得太多，请 10 分钟后再试' : '动态码不正确';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _checkingTotp = false);
    }
  }

  void _verify() {
    for (final i in _quizIdx) {
      final input = _ctrls[i]!.text.trim().toLowerCase();
      if (input != _mnemonic[i].toLowerCase()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('验证失败，请检查单词是否正确')));
        return;
      }
    }
    setState(() => _phase = 'show');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: const Text('查看助记词'),
      ),
      body: ReadingWidth(
        maxWidth: WindowLayout.formMaxWidth,
        child: _mnemonic.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _phase == 'totp'
            ? _buildTotp()
            : _phase == 'verify'
            ? _buildVerify()
            : _buildShow(),
      ),
    );
  }

  Widget _scrollForm({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.all(24);
        final minHeight = (constraints.maxHeight - padding.vertical).clamp(
          0.0,
          double.infinity,
        );
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotp() => _scrollForm(
    children: [
      const Text(
        '查看助记词前，先输入验证器上的 6 位动态码，或一个备用码。',
        style: TextStyle(fontSize: 15, height: 1.6),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _totpCode,
        enabled: !_checkingTotp,
        decoration: const InputDecoration(
          labelText: '动态码或备用码',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _checkTotp(),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _checkingTotp ? null : _checkTotp,
        child: Text(_checkingTotp ? '正在确认…' : '确认动态码'),
      ),
    ],
  );

  Widget _buildVerify() => _scrollForm(
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '助记词是你账户的唯一凭证，请确保周围没有他人。',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      const Text(
        '为了确认是本人操作，\n请输入以下位置的助记词单词：',
        style: TextStyle(fontSize: 15, height: 1.6),
      ),
      const SizedBox(height: 20),
      for (final i in _quizIdx) ...[
        TextField(
          controller: _ctrls[i],
          decoration: InputDecoration(
            labelText: '第 ${i + 1} 个单词',
            border: const OutlineInputBorder(),
          ),
          autocorrect: false,
          enableSuggestions: false,
        ),
        const SizedBox(height: 14),
      ],
      const SizedBox(height: 8),
      FilledButton(onPressed: _verify, child: const Text('确认身份')),
    ],
  );

  Widget _buildShow() => _scrollForm(
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
          '不要截屏发给别人，也不要粘贴到聊天里。\n'
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
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${i + 1}. ${_mnemonic[i]}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        '离开此页面后，助记词不会再自动显示。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
    ],
  );
}
