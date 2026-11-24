import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// 签名通过后，向用户要动态码或备用码，成功时返回登录令牌。
class TotpPrompt {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.workersBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static Future<String?> complete(String totpToken) async {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      debugPrint('[身份] 二次验证界面还没准备好');
      return null;
    }
    return showDialog<String>(
      context: nav.context,
      barrierDismissible: false,
      builder: (_) => _TotpLoginDialog(totpToken: totpToken),
    );
  }

  static Future<String> submit(String totpToken, String code) async {
    final res = await _dio.post(
      '/auth/totp',
      data: {'totp_token': totpToken, 'code': code.trim()},
    );
    final jwt = res.data['jwt'] as String?;
    if (jwt == null || jwt.isEmpty) throw Exception('缺少登录令牌');
    return jwt;
  }
}

class _TotpLoginDialog extends StatefulWidget {
  const _TotpLoginDialog({required this.totpToken});

  final String totpToken;

  @override
  State<_TotpLoginDialog> createState() => _TotpLoginDialogState();
}

class _TotpLoginDialogState extends State<_TotpLoginDialog> {
  final _code = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final jwt = await TotpPrompt.submit(widget.totpToken, code);
      if (!mounted) return;
      Navigator.of(context).pop(jwt);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = _message(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '没能完成验证：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(DioException e) {
    if (e.response?.statusCode == 429) return '试得太多，请 10 分钟后再试';
    final data = e.response?.data;
    final raw = data is Map ? data['error']?.toString() : null;
    if (raw == 'Ticket expired') return '验证已超时，请重新登录';
    if (raw == 'Invalid code') return '动态码不正确';
    return '没能完成验证，请再试一次';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('二次验证'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('输入验证器上的 6 位动态码，或一个备用码。'),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            autofocus: true,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: '动态码或备用码',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确认'),
        ),
      ],
    );
  }
}
