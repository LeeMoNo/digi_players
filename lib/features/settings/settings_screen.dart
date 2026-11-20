// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/reading_width.dart';
import '../../core/layout/window_layout_host.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/storage/secure_storage.dart';
import '../points/profile_repository.dart';
import 'language_screen.dart';
import 'theme_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.selectedDetail});

  final String? selectedDetail;

  void _open(BuildContext context, String detail) {
    if (detail == selectedDetail) return;
    final location = '/settings/$detail';
    if (!WindowLayoutScope.layoutOf(context).canSplit) {
      context.push(location);
      return;
    }
    if (selectedDetail != null) {
      context.pushReplacement(location);
    } else {
      context.push(location);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ReadingWidth(
        child: ListView(
          children: [
            // ── 个人资料 ──────────────────────────────────
            _SectionHeader('个人资料'),
            ListTile(
              selected: selectedDetail == 'nickname',
              leading: const Icon(Icons.badge_outlined),
              title: const Text('我的昵称'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, 'nickname'),
            ),

            // ── 显示 ──────────────────────────────────────
            _SectionHeader('显示'),
            ListTile(
              selected: selectedDetail == 'language',
              leading: const Icon(Icons.language),
              title: const Text('语言'),
              subtitle: const Text('学习内容、练习和每日题仍是简体中文'),
              trailing: _CurrentValue(languageLabelOf(settings.locale)),
              onTap: () => _open(context, 'language'),
            ),
            ListTile(
              selected: selectedDetail == 'theme',
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('主题'),
              trailing: _CurrentValue(themeLabelOf(settings.themeMode)),
              onTap: () => _open(context, 'theme'),
            ),

            // ── 安全 ──────────────────────────────────────
            _SectionHeader('安全'),
            ListTile(
              selected: selectedDetail == 'mnemonic',
              leading: const Icon(Icons.vpn_key_outlined),
              title: const Text('查看助记词'),
              subtitle: const Text(
                '助记词就是这个学习账号。换一台设备用同一组词登录，进度还在。把词交给别人，对方看到的也是这份进度。',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, 'mnemonic'),
            ),

            // ── 关于 ──────────────────────────────────────
            _SectionHeader('关于'),
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
      ProfileCache.clear();
      await SecureStorage.clearAll();
      if (context.mounted) context.go('/register');
    }
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
