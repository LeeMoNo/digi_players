// lib/features/settings/nickname_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});
  @override State<NicknameScreen> createState() => _State();
}

class _State extends State<NicknameScreen> {
  final _ctrl    = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving   = false;
  String? _currentName;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _loadCurrent() async {
    try {
      final res = await ApiClient.dio.get('/user/profile');
      final name = res.data['display_name'] as String?;
      if (name != null && mounted) {
        setState(() { _currentName = name; _ctrl.text = name; });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      await ApiClient.dio.patch('/user/profile',
          data: {'display_name': _ctrl.text.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('昵称已保存 ✓')));
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = _friendlyError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$msg')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(DioException e) {
    if (e.response?.statusCode == 401) {
      return '登录已过期，请完全退出应用后重新打开，或重新完成身份验证';
    }
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'].toString();
    if (data is String && data.isNotEmpty) return data;
    return '网络错误，请稍后重试';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置昵称')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_currentName == null)
                const Text('昵称将显示在排行榜中，让其他数字游民认识你。',
                    style: TextStyle(color: Colors.grey))
              else
                Text('当前昵称：$_currentName',
                    style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              TextFormField(
                controller: _ctrl,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: '你的昵称',
                  hintText: '2～20 个字符',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.length < 2) return '昵称至少 2 个字符';
                  if (s.length > 20) return '昵称最多 20 个字符';
                  if (RegExp(r'[<>&]').hasMatch(s)) return '包含非法字符';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: Colors.white))
                    : const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}