import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/reading_width.dart';
import '../../core/layout/window_layout.dart';
import '../../core/providers/app_settings_provider.dart';

class ThemeChoice {
  const ThemeChoice({
    required this.mode,
    required this.label,
    required this.icon,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
}

/// 新增外观时，在这里加一项。
const themeChoices = <ThemeChoice>[
  ThemeChoice(
    mode: ThemeMode.system,
    label: '跟随系统',
    icon: Icons.brightness_auto_outlined,
  ),
  ThemeChoice(
    mode: ThemeMode.light,
    label: '浅色',
    icon: Icons.light_mode_outlined,
  ),
  ThemeChoice(
    mode: ThemeMode.dark,
    label: '深色',
    icon: Icons.dark_mode_outlined,
  ),
];

String themeLabelOf(ThemeMode mode) {
  for (final choice in themeChoices) {
    if (choice.mode == mode) return choice.label;
  }
  return themeChoices.first.label;
}

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appSettingsProvider).themeMode;

    return Scaffold(
      appBar: AppBar(title: const Text('主题')),
      body: ReadingWidth(
        maxWidth: WindowLayout.formMaxWidth,
        child: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              ref.read(appSettingsProvider.notifier).setTheme(value);
            }
          },
          child: ListView(
            children: [
              for (final choice in themeChoices)
                RadioListTile<ThemeMode>(
                  value: choice.mode,
                  secondary: Icon(choice.icon),
                  title: Text(choice.label),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
