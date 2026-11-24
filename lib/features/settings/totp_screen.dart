import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/api/api_client.dart';
import '../../core/layout/reading_width.dart';
import '../../core/layout/window_layout.dart';
import '../../core/router/app_back_button.dart';

/// 与服务端 `SETUP_TTL` 一致：二维码 15 分钟有效。
const setupTtl = Duration(minutes: 15);

class TotpSetup {
  const TotpSetup({
    required this.secret,
    required this.otpauthUrl,
    required this.expiresAt,
  });

  final String secret;
  final String otpauthUrl;
  final DateTime expiresAt;
}

class TotpEnableResult {
  const TotpEnableResult({required this.backupCodes, this.pointsAwarded = 0});

  final List<String> backupCodes;
  final int pointsAwarded;
}

class TotpScreen extends StatefulWidget {
  const TotpScreen({
    super.key,
    this.loadEnabled,
    this.startSetup,
    this.enable,
    this.disable,
  });

  final Future<bool> Function()? loadEnabled;
  final Future<TotpSetup> Function()? startSetup;
  final Future<TotpEnableResult> Function(String code)? enable;
  final Future<void> Function(String code)? disable;

  @override
  State<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends State<TotpScreen> {
  final _code = TextEditingController();
  bool? _enabled;
  TotpSetup? _setup;
  List<String>? _backupCodes;
  var _pointsAwarded = 0;
  var _busy = false;
  var _copied = false;
  String? _error;
  Timer? _expiryTimer;
  Duration _remaining = Duration.zero;

  bool get _setupExpired {
    final setup = _setup;
    if (setup == null) return false;
    return !DateTime.now().isBefore(setup.expiresAt);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _watchExpiry(TotpSetup setup) {
    _expiryTimer?.cancel();
    void tick() {
      final left = setup.expiresAt.difference(DateTime.now());
      if (!mounted) return;
      setState(() {
        _remaining = left.isNegative ? Duration.zero : left;
        if (left.isNegative || left == Duration.zero) {
          _error ??= '二维码已过期，请重新生成后再扫';
        }
      });
      if (left.isNegative || left == Duration.zero) {
        _expiryTimer?.cancel();
      }
    }

    tick();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _load() async {
    try {
      final enabled = await (widget.loadEnabled ?? _loadEnabled)();
      if (!mounted) return;
      setState(() => _enabled = enabled);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _error = '暂时没能确认开启状态';
      });
    }
  }

  Future<void> _begin() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final setup = await (widget.startSetup ?? _startSetup)();
      if (!mounted) return;
      setState(() {
        _setup = setup;
        _code.clear();
      });
      _watchExpiry(setup);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = _message(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '没能生成密钥：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final code = _code.text.trim();
    if (code.length < 6 || _busy) return;
    if (_setupExpired) {
      setState(() => _error = '二维码已过期，请重新生成后再扫');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await (widget.enable ?? _enable)(code);
      if (!mounted) return;
      _expiryTimer?.cancel();
      setState(() {
        _enabled = true;
        _setup = null;
        _backupCodes = result.backupCodes;
        _pointsAwarded = result.pointsAwarded;
        _copied = false;
        _remaining = Duration.zero;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = _message(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '没能开启：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _turnOff() async {
    final code = _code.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (widget.disable ?? _disable)(code);
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _code.clear();
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = _message(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '没能关闭：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(DioException e) {
    if (e.response?.statusCode == 429) return '试得太多，请 10 分钟后再试';
    final data = e.response?.data;
    final raw = data is Map ? data['error']?.toString() : null;
    if (raw == 'Invalid code') return '动态码不正确';
    if (raw == 'Setup expired') {
      return '二维码已过期（有效期 15 分钟），请点「重新生成二维码」后再扫';
    }
    if (e.response?.statusCode == 401) return '登录状态没能刷新，请检查网络后再试';
    return '没能完成，请再试一次';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: const Text('二次验证'),
      ),
      body: ReadingWidth(
        maxWidth: WindowLayout.formMaxWidth,
        child: _enabled == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (_backupCodes != null)
                    _backup(context)
                  else ...[
                    const _Explain(),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_enabled == true)
                      _disableForm()
                    else if (_setup != null)
                      _setupForm(context)
                    else
                      FilledButton(
                        onPressed: _busy ? null : _begin,
                        child: Text(_busy ? '正在生成…' : '开启验证器动态码'),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _setupForm(BuildContext context) {
    final setup = _setup!;
    final grouped = _groupSecret(setup.secret);
    final expired = _setupExpired;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('打开验证器扫下面的二维码，再把里面显示的 6 位数填进来。确认之前还没有生效。'),
        const SizedBox(height: 8),
        Text(
          expired
              ? '二维码已过期，请重新生成后再扫。'
              : '二维码有效期 15 分钟，还剩 ${_formatRemaining(_remaining)}。过期后需要重新生成。',
          style: TextStyle(
            color: expired ? scheme.error : scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Opacity(
            opacity: expired ? 0.35 : 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: QrImageView(data: setup.otpauthUrl, size: 200),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(
          grouped,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          '扫不了也可以：在验证器里选「手动输入密钥」，把上面这串字符贴进去。',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          enabled: !_busy && !expired,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: '6 位动态码',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _confirm(),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: (_busy || expired) ? null : _confirm,
          child: Text(_busy ? '正在确认…' : '确认开启'),
        ),
        TextButton(
          onPressed: _busy ? null : _begin,
          child: Text(expired ? '二维码已过期，重新生成' : '重新生成二维码'),
        ),
      ],
    );
  }

  Widget _disableForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('已开启。换设备登录时，签名之后还要输入验证器上的动态码或一个备用码。'),
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: '动态码或备用码',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy ? null : _turnOff,
          child: const Text('关闭二次验证'),
        ),
      ],
    );
  }

  Widget _backup(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_pointsAwarded > 0) ...[
          Text(
            '二次验证已开启，获得 $_pointsAwarded 积分。',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
        ],
        const Text(
          '这 8 个备用码只显示这一次。验证器丢了，就靠它们登录。每个只能用一次。',
          style: TextStyle(height: 1.5),
        ),
        const SizedBox(height: 16),
        for (final code in _backupCodes!)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 18),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: _backupCodes!.join('\n')),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('备用码已复制，请尽快抄到纸上')));
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('复制备用码'),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _copied,
          onChanged: (value) => setState(() => _copied = value ?? false),
          title: const Text('我已抄下备用码'),
        ),
        FilledButton(
          onPressed: _copied
              ? () => setState(() {
                  _backupCodes = null;
                  _pointsAwarded = 0;
                  _code.clear();
                })
              : null,
          child: const Text('完成'),
        ),
      ],
    );
  }
}

class _Explain extends StatelessWidget {
  const _Explain();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final muted = style?.copyWith(color: Colors.grey.shade700, height: 1.45);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('助记词证明你拿着这把钥匙。钥匙被抄走，对方就是这个账号。二次验证再要一件只有你随身带着的东西。', style: style),
        const SizedBox(height: 16),
        Text('怎么开（以谷歌验证器为例）', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          '1. 在应用商店搜索「Google Authenticator / 谷歌验证器」并安装。'
          '也可用微软验证器、Authy、1Password 等同类应用。\n'
          '2. 点下面「开启验证器动态码」，会出现一个二维码（有效期 15 分钟）。\n'
          '3. 打开验证器，选「扫描二维码」对准屏幕；扫不了就选手动输入密钥。\n'
          '4. 把验证器里不断变化的 6 位数填回来，点确认。\n'
          '5. 立刻抄下备用码并收好。验证器丢了，就靠它们登录。',
          style: muted,
        ),
        const SizedBox(height: 16),
        Text('行业里常见的三种做法', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          '· 验证器动态码：每 30 秒变一个 6 位数，断网也能出码。这里先做这个。\n'
          '· 通行密钥：用手机或硬件钥匙签名，没有可以抄走的数字。这一版先不做。\n'
          '· 邮箱或短信：用得最多，也最容易被骗。这里不做邮箱和短信。',
          style: muted,
        ),
      ],
    );
  }
}

String _groupSecret(String secret) {
  final buffer = StringBuffer();
  for (var i = 0; i < secret.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(secret[i]);
  }
  return buffer.toString();
}

String _formatRemaining(Duration left) {
  final total = left.inSeconds;
  if (total <= 0) return '0 分 0 秒';
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return '$minutes 分 ${seconds.toString().padLeft(2, '0')} 秒';
}

Future<bool> _loadEnabled() async {
  final res = await ApiClient.dio.get('/user/profile');
  final data = res.data;
  return data is Map && data['totp_enabled'] == true;
}

Future<TotpSetup> _startSetup() async {
  final res = await ApiClient.dio.post('/user/totp/setup');
  final data = res.data;
  if (data is! Map) throw Exception('响应无效');
  return TotpSetup(
    secret: data['secret'] as String,
    otpauthUrl: data['otpauth_url'] as String,
    expiresAt: DateTime.now().add(setupTtl),
  );
}

Future<TotpEnableResult> _enable(String code) async {
  final res = await ApiClient.dio.post(
    '/user/totp/enable',
    data: {'code': code},
  );
  final data = res.data;
  if (data is! Map) throw Exception('响应无效');
  final raw = data['backup_codes'];
  if (raw is! List) throw Exception('没有备用码');
  final points = data['points_awarded'];
  return TotpEnableResult(
    backupCodes: raw.map((item) => item.toString()).toList(),
    pointsAwarded: points is int ? points : int.tryParse('$points') ?? 0,
  );
}

Future<void> _disable(String code) async {
  await ApiClient.dio.post('/user/totp/disable', data: {'code': code});
}
