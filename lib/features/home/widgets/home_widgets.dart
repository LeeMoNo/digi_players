import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/home_content.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class FraudSummarySection extends StatelessWidget {
  const FraudSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final previews = HomeContent.fraudPreviewScamIds
        .map(HomeContent.scamById)
        .whereType<FraudScamPattern>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(
          title: '警防诈骗',
          subtitle: '安全清单与常见套路',
          trailing: TextButton(
            onPressed: () => context.push('/home/fraud'),
            child: const Text('查看全部'),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('安全清单',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                ...HomeContent.fraudChecklist.take(4).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.shortTitle)),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: previews.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final scam = previews[i];
              return SizedBox(
                width: 200,
                child: Card(
                  child: InkWell(
                    onTap: () => context.push('/home/fraud?scam=${scam.id}'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(scam.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              scam.summary,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TimelineSection extends StatefulWidget {
  const TimelineSection({super.key});

  @override
  State<TimelineSection> createState() => _TimelineSectionState();
}

class _TimelineSectionState extends State<TimelineSection> {
  bool _expanded = false;

  static const _collapsedCount = 5;

  @override
  Widget build(BuildContext context) {
    final events = HomeContent.timelineEvents;
    final visible = _expanded ? events : events.take(_collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSectionTitle(
          title: '加密货币发展年史',
          subtitle: '关键里程碑（精确到月）',
        ),
        ...visible.map((e) => _TimelineTile(event: e)),
        if (events.length > _collapsedCount)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? '收起' : '查看更早 / 更晚'),
          ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSecurity = event.type == TimelineEventType.security;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isSecurity ? colorScheme.error : colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(child: Container(width: 2, color: colorScheme.outlineVariant)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(event.yearMonth,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          )),
                      const SizedBox(width: 8),
                      _TypeChip(label: HomeContent.timelineTypeLabel(event.type)),
                      if (event.related != null) ...[
                        const SizedBox(width: 8),
                        Text(event.related!,
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(event.title),
                  if (event.fraudScamId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context.push(
                          '/home/fraud?scam=${event.fraudScamId}',
                        ),
                        child: const Text('了解相关诈骗套路 →'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class GlossarySection extends StatelessWidget {
  const GlossarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<GlossaryTerm>>{};
    for (final t in HomeContent.glossaryTerms) {
      groups.putIfAbsent(t.group, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSectionTitle(
          title: '概念速查',
          subtitle: '术语速览；展开查看定义',
        ),
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(HomeContent.shitcoinLifecycleTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                const SizedBox(height: 8),
                ...HomeContent.shitcoinLifecycleSteps.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('${e.key + 1}. ${e.value}'),
                      ),
                    ),
                TextButton(
                  onPressed: () => context.push('/home/fraud?scam=rug_pull'),
                  child: const Text('了解 Rug Pull / 庞氏盘 →'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...groups.entries.map(
          (entry) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                ListTile(
                  title: Text(entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                ...entry.value.map(
                  (t) => ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(t.term),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.definition),
                            if (t.learnChapterHint != null) ...[
                              const SizedBox(height: 8),
                              Text(t.learnChapterHint!,
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FlowOverviewSection extends StatelessWidget {
  const FlowOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSectionTitle(
          title: '流程速览',
          subtitle: '一笔资产如何在链与钱包间流动',
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: HomeContent.flowOverviews.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final flow = HomeContent.flowOverviews[i];
              return SizedBox(
                width: 260,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(flow.title,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: flow.steps.length,
                            itemBuilder: (_, j) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('${j + 1}. ${flow.steps[j]}',
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/learn'),
                            child: const Text('去学程'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class LearnMapSection extends StatelessWidget {
  const LearnMapSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSectionTitle(title: '学习地图', subtitle: '按主题进入系统学程'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HomeContent.learnMapEntries.map((e) {
            return SizedBox(
              width: (MediaQuery.sizeOf(context).width - 48) / 2,
              child: Card(
                child: InkWell(
                  onTap: () => context.push('/learn'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(e.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ExternalLinksSection extends StatelessWidget {
  const ExternalLinksSection({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开链接：$url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSectionTitle(
          title: '权威延伸阅读',
          subtitle: '将在系统浏览器中打开',
        ),
        ...HomeContent.externalResources.map(
          (r) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(r.title),
              subtitle: Text(
                [r.description, if (r.note != null) '（${r.note}）'].join('\n'),
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openUrl(context, r.url),
            ),
          ),
        ),
      ],
    );
  }
}

class GamesEntrySection extends StatelessWidget {
  const GamesEntrySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSectionTitle(
          title: '游戏',
          subtitle: '用小游戏把概念练熟（章节解锁）',
        ),
        Card(
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.sports_esports_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('进入游戏大厅'),
            subtitle: const Text('哈希碰碰乐 · 反诈识别训练营'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/games'),
          ),
        ),
      ],
    );
  }
}
