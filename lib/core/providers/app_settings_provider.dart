import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/api/api_client.dart';

// ── 数据模型 ──────────────────────────────────────────

class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;

  const AppSettings({
    this.locale = const Locale('zh', 'CN'),
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({Locale? locale, ThemeMode? themeMode}) => AppSettings(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.locale == locale &&
      other.themeMode == themeMode;

  @override
  int get hashCode => Object.hash(locale, themeMode);
}

// ── Notifier ──────────────────────────────────────────

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _boxName = 'app_settings';
  static const _keyLang = 'lang';
  static const _keyTheme = 'theme';

  @override
  AppSettings build() {
    Future.microtask(_loadFromHive);
    return const AppSettings();
  }

  Future<void> _loadFromHive() async {
    final box = await Hive.openBox(_boxName);
    final lang = box.get(_keyLang, defaultValue: 'zh_CN') as String;
    final theme = box.get(_keyTheme, defaultValue: 'system') as String;

    state = AppSettings(
      locale: _langToLocale(lang),
      themeMode: _stringToTheme(theme),
    );
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(locale: _langToLocale(lang));
    final box = await Hive.openBox(_boxName);
    await box.put(_keyLang, lang);

    try {
      await ref.read(_apiClientProvider).patch('/user/profile', data: {'lang': lang});
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final box = await Hive.openBox(_boxName);
    await box.put(_keyTheme, _themeToString(mode));
  }

  static Locale _langToLocale(String lang) => switch (lang) {
        'zh_TW' => const Locale('zh', 'TW'),
        'en' => const Locale('en'),
        _ => const Locale('zh', 'CN'),
      };

  static ThemeMode _stringToTheme(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _themeToString(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}

// ── Provider 定义 ────────────────────────────────────

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

final _apiClientProvider = Provider((_) => ApiClient.dio);
