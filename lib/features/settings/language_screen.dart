import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/reading_width.dart';
import '../../core/router/app_back_button.dart';
import '../../core/layout/window_layout.dart';
import '../../core/providers/app_settings_provider.dart';

class LanguageChoice {
  const LanguageChoice({required this.code, required this.label});

  final String code;
  final String label;
}

/// 新增界面语言时，在这里加一项。
const languageChoices = <LanguageChoice>[
  LanguageChoice(code: 'zh_CN', label: '简体中文'),
  LanguageChoice(code: 'zh_TW', label: '繁體中文'),
  LanguageChoice(code: 'en', label: 'English'),
];

String languageCodeOf(Locale locale) {
  if (locale.countryCode == 'TW') return 'zh_TW';
  if (locale.languageCode == 'en') return 'en';
  return 'zh_CN';
}

String languageLabelOf(Locale locale) {
  final code = languageCodeOf(locale);
  for (final choice in languageChoices) {
    if (choice.code == code) return choice.label;
  }
  return languageChoices.first.label;
}

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final current = languageCodeOf(settings.locale);

    return Scaffold(
      appBar: AppBar(leading: appBarLeading(context), title: const Text('语言')),
      body: ReadingWidth(
        maxWidth: WindowLayout.formMaxWidth,
        child: RadioGroup<String>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              ref.read(appSettingsProvider.notifier).setLanguage(value);
            }
          },
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '学习内容、练习和每日题仍是简体中文',
                  style: TextStyle(color: Colors.grey, height: 1.4),
                ),
              ),
              for (final choice in languageChoices)
                RadioListTile<String>(
                  value: choice.code,
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
