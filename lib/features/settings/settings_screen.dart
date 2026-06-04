// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_settings_provider.dart';
import '../../core/storage/secure_storage.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [

          // ── 个人资料 ──────────────────────────────────
          _SectionHeader('个人资料'),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('我的昵称'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/nickname'),
          ),

          // ── 显示 ──────────────────────────────────────
          _SectionHeader('显示'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('语言'),
            trailing: _LangSelector(
              current: _localeToLangCode(settings.locale),
              onChanged: (lang) => notifier.setLanguage(lang),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('主题'),
            trailing: _ThemeSelector(
              current: settings.themeMode,
              onChanged: (mode) => notifier.setTheme(mode),
            ),
          ),

          // ── 安全 ──────────────────────────────────────
          _SectionHeader('安全'),
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('查看助记词'),
            subtitle: const Text('需要验证身份'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/mnemonic'),
          ),

          // ── 关于 ──────────────────────────────────────
          _SectionHeader('关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            trailing: const Text('0.2.0',
                style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录',
                style: TextStyle(color: Colors.red)),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  String _localeToLangCode(Locale locale) {
    if (locale.countryCode == 'TW') return 'zh_TW';
    if (locale.languageCode == 'en') return 'en';
    return 'zh_CN';
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text(
            '退出后需要用助记词重新登录。\n请确保你已经安全保存了助记词。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('退出')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await SecureStorage.clearAll();
      context.go('/register');
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
    child: Text(title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        )),
  );
}

class _LangSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _LangSelector({required this.current, required this.onChanged});

  static const _options = [
    ('zh_CN', '简体中文'),
    ('zh_TW', '繁體中文'),
    ('en',    'English'),
  ];

  @override
  Widget build(BuildContext context) => DropdownButton<String>(
    value: current,
    underline: const SizedBox(),
    items: _options.map((o) => DropdownMenuItem(
      value: o.$1,
      child: Text(o.$2),
    )).toList(),
    onChanged: (v) { if (v != null) onChanged(v); },
  );
}

class _ThemeSelector extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeSelector({required this.current, required this.onChanged});

  static const _options = [
    (ThemeMode.system, '跟随系统'),
    (ThemeMode.light,  '浅色'),
    (ThemeMode.dark,   '深色'),
  ];

  @override
  Widget build(BuildContext context) => DropdownButton<ThemeMode>(
    value: current,
    underline: const SizedBox(),
    items: _options.map((o) => DropdownMenuItem(
      value: o.$1,
      child: Text(o.$2),
    )).toList(),
    onChanged: (v) { if (v != null) onChanged(v); },
  );
}