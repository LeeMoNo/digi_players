import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/did/did_auth.dart';
import 'core/providers/app_settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';

const _seedColor = Color(0xFF6366F1);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final hasIdentity = await SecureStorage.hasIdentity();
  if (hasIdentity) {
    try {
      await DIDAuth.ensureSession();
    } catch (_) {
      // 密钥异常时仍进入应用，受保护接口会提示重新认证
    }
  }
  final initialLocation = hasIdentity ? '/learn' : '/register';

  runApp(
    ProviderScope(
      overrides: [
        initialLocationProvider.overrideWithValue(initialLocation),
      ],
      child: const DigiPlayersApp(),
    ),
  );
}

class DigiPlayersApp extends ConsumerWidget {
  const DigiPlayersApp({super.key});

  static ThemeData lightTheme() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      );

  static ThemeData darkTheme() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        useMaterial3: true,
      );

  static ThemeData _resolveTheme(BuildContext context, AppSettings settings) {
    final brightness = switch (settings.themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
    return brightness == Brightness.dark ? darkTheme() : lightTheme();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // 主题/语言变化时强制重建，避免 go_router 子树不刷新配色
      key: ValueKey('${settings.themeMode.name}_${settings.locale.toLanguageTag()}'),
      title: 'DigiPlayers',
      debugShowCheckedModeBanner: false,
      locale: settings.locale,
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: settings.themeMode,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      routerConfig: router,
      builder: (context, child) {
        return Theme(
          data: _resolveTheme(context, settings),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
