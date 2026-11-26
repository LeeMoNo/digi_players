// lib/features/settings/settings_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/layout/chevron_inset.dart';
import '../../core/layout/reading_width.dart';
import '../../core/progress/progress_store.dart';
import '../../core/router/app_back_button.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/storage/secure_storage.dart';
import '../games/games_home_screen.dart';
import '../learn/learn_home_screen.dart';
import '../points/profile_repository.dart';
import 'language_screen.dart';
import 'settings_split.dart';
import 'theme_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.selectedDetail});

  final String? selectedDetail;

  void _open(BuildContext context, String detail) {
    if (detail == selectedDetail) return;
    final location = '/settings/$detail';
    // 跟分栏壳实际是否切开对齐；设置藏侧栏后，比 layout.canSplit 更宽也能双栏。
    if (!SettingsSplitScope.splittingOf(context)) {
      context.push(location);
      return;
    }
    final path = GoRouterState.of(context).uri.path;
    const prefix = '/settings/';
    final opened =
        path.startsWith(prefix) &&
        path.substring(prefix.length).isNotEmpty &&
        !path.substring(prefix.length).contains('/');
    if (opened) {
      context.pushReplacement(location);
    } else {
      context.push(location);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(leading: appBarLeading(context), title: const Text('设置')),
      body: ReadingWidth(
        child: ListView(
          children: [
            // ── 个人资料 ──────────────────────────────────
            _SectionHeader('个人资料'),
            ListTile(
              contentPadding: chevronTilePadding,
              selected: selectedDetail == 'nickname',
              leading: const Icon(Icons.badge_outlined),
              title: const Text('我的昵称'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, 'nickname'),
            ),
            ListTile(
              contentPadding: chevronTilePadding,
              selected: selectedDetail == 'avatar',
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('我的头像'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, 'avatar'),
            ),

            // ── 显示 ──────────────────────────────────────
            _SectionHeader('显示'),
            ListTile(
              contentPadding: chevronTilePadding,
              selected: selectedDetail == 'language',
              leading: const Icon(Icons.language),
              title: const Text('语言'),
              subtitle: const Text('学习内容、练习和每日题仍是简体中文'),
              trailing: _CurrentValue(languageLabelOf(settings.locale)),
              onTap: () => _open(context, 'language'),
            ),
            ListTile(
              contentPadding: chevronTilePadding,
              selected: selectedDetail == 'theme',
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('主题'),
              trailing: _CurrentValue(themeLabelOf(settings.themeMode)),
              onTap: () => _open(context, 'theme'),
            ),

            // ── 安全 ──────────────────────────────────────
            _SectionHeader('安全'),
            ListTile(
              contentPadding: chevronTilePadding,
              selected: selectedDetail == 'mnemonic',
              leading: const Icon(Icons.vpn_key_outlined),
              title: const Text('查看助记词'),
              subtitle: const Text(
                '助记词就是这个学习账号。换一台设备用同一组词登录，进度还在。把词交给别人，对方看到的也是这份进度。',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, 'mnemonic'),
            ),
            ListTile(
              contentPadding: chevronTilePadding,
              selected: selectedDetail == 'totp',
              leading: const Icon(Icons.phonelink_lock_outlined),
              title: const Text('二次验证'),
              subtitle: const Text('验证器动态码。助记词之外，再要一个 30 秒一变的数字。'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, 'totp'),
            ),

            // ── 关于 ──────────────────────────────────────
            _SectionHeader('关于'),
            ListTile(
              contentPadding: chevronTilePadding,
              selected: selectedDetail == 'privacy',
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('隐私政策'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, 'privacy'),
            ),
            ListTile(
              contentPadding: chevronTilePadding,
              selected: selectedDetail == 'terms',
              leading: const Icon(Icons.description_outlined),
              title: const Text('用户协议'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, 'terms'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('版本'),
              trailing: const Text(
                '1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('退出登录', style: TextStyle(color: Colors.red)),
              onTap: () => _confirmLogout(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: const Text('删除账号', style: TextStyle(color: Colors.red)),
              subtitle: const Text('清除服务器进度与本机钥匙，不能撤销'),
              onTap: () => _confirmDeleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出后需要用助记词重新登录。\n请确保你已经安全保存了助记词。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await _clearLocalSession();
      if (context.mounted) context.go('/register');
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _DeleteAccountDialog(),
    );
    if (confirmed != true) return;

    try {
      await ApiClient.dio.delete('/user/account');
    } on DioException catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('没删成，请检查网络后重试')),
      );
      return;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('没删成，请检查网络后重试')),
      );
      return;
    }

    final did = await SecureStorage.getDID();
    await _clearLocalSession();
    router.go('/register');
    // 跳转后再清进度盒，避免本机存储卡住删号流程；同词登录后 pull 也会覆盖。
    if (did != null && did.isNotEmpty) {
      try {
        await ProgressStore.clearLocalCacheFor(did);
      } catch (_) {}
    }
  }

  Future<void> _clearLocalSession() async {
    ProfileCache.clear();
    LearnHomeCache.clear();
    GamesHomeCache.clear();
    await SecureStorage.clearAll();
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canConfirm => _controller.text.trim() == '删除';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('删除账号'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '会删除服务器上这个身份的进度、积分、昵称和头像。本机钥匙也会清掉。'
            '助记词无法帮你找回已删的数据。此操作不能撤销。',
          ),
          const SizedBox(height: 16),
          const Text('请输入「删除」以确认：'),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '删除',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_canConfirm) Navigator.pop(context, true);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _canConfirm ? () => Navigator.pop(context, true) : null,
          child: const Text('确认删除'),
        ),
      ],
    );
  }
}

// ── 子组件 ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _CurrentValue extends StatelessWidget {
  const _CurrentValue(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right),
      ],
    );
  }
}
