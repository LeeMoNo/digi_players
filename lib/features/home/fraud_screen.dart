import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/reading_width.dart';
import '../../core/router/app_back_button.dart';
import 'data/home_content.dart';

/// 警防诈骗子页：安全清单全文、套路库、识别信号、出事怎么办
class FraudScreen extends StatelessWidget {
  const FraudScreen({super.key, this.highlightScamId});

  final String? highlightScamId;

  @override
  Widget build(BuildContext context) {
    // 从反诈练习链过来时，把对应条目提到套路区最前，返回后练习页还在栈里。
    final scams = [
      if (highlightScamId != null)
        for (final scam in HomeContent.fraudScamPatterns)
          if (scam.id == highlightScamId) scam,
      for (final scam in HomeContent.fraudScamPatterns)
        if (scam.id != highlightScamId) scam,
    ];

    final scamSection = <Widget>[
      const _SectionHeader(title: '常见套路', icon: Icons.warning_amber_outlined),
      for (final scam in scams)
        _ScamCard(
          scam: scam,
          highlighted: scam.id == highlightScamId,
        ),
    ];

    final checklistSection = <Widget>[
      const _SectionHeader(title: '安全清单', icon: Icons.verified_user_outlined),
      for (final item in HomeContent.fraudChecklist) _ChecklistTile(item: item),
    ];

    // 带 ?scam= 进来时，先看到对应套路，避免清单把高亮条目挤出首屏。
    final leading = highlightScamId != null ? scamSection : checklistSection;
    final trailing = highlightScamId != null ? checklistSection : scamSection;

    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: const Text('警防诈骗'),
      ),
      body: ReadingWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...leading,
            const SizedBox(height: 24),
            ...trailing,
            const SizedBox(height: 24),
            const _SectionHeader(title: '识别信号', icon: Icons.search_outlined),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: HomeContent.fraudRecognitionSignals
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(s)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: '出事怎么办', icon: Icons.emergency_outlined),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < HomeContent.fraudWhatToDo.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(HomeContent.fraudWhatToDo[i])),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.item});

  final FraudChecklistItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          item.shortTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(item.detail),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScamCard extends StatelessWidget {
  const _ScamCard({required this.scam, this.highlighted = false});

  final FraudScamPattern scam;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: highlighted
          ? colorScheme.errorContainer.withValues(alpha: 0.3)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scam.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(scam.detail),
            const SizedBox(height: 12),
            Text('识别信号', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            ...scam.signals.map(
              (s) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 从学习页/时间线跳转时可带 query：/learn/fraud?scam=rug_pull
FraudScreen fraudScreenFromState(GoRouterState state) {
  return FraudScreen(highlightScamId: state.uri.queryParameters['scam']);
}
