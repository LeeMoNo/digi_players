import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/chevron_inset.dart';
import '../../core/layout/reading_width.dart';
import '../../core/router/app_back_button.dart';
import '../home/data/home_content.dart';
import '../home/widgets/home_widgets.dart';
import 'library_split.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, this.selectedEraId});

  final String? selectedEraId;

  void _openEra(BuildContext context, String eraId) {
    if (eraId == selectedEraId) return;
    final location = '/learn/library/$eraId';
    if (!LibrarySplitScope.splittingOf(context)) {
      context.push(location);
      return;
    }
    final path = GoRouterState.of(context).uri.path;
    const prefix = '/learn/library/';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: appBarLeading(context), title: const Text('资料')),
      body: ReadingWidth(
        child: ListView(
          key: const Key('library-scroll'),
          padding: const EdgeInsets.all(16),
          children: [
            Text('按概念出现的时间', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              HomeContent.tagline,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            for (final era in HomeContent.eraSections) ...[
              Card(
                child: ListTile(
                  contentPadding: chevronTilePadding,
                  selected: era.id == selectedEraId,
                  title: Text(era.heading),
                  subtitle: era.besidePath == null
                      ? null
                      : Text('配合「${era.besidePath}」阅读'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openEra(context, era.id),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push('/learn/fraud'),
                child: const Text('警防诈骗全文'),
              ),
            ),
            const SizedBox(height: 24),
            const LearnMapSection(),
            const SizedBox(height: 32),
            const ExternalLinksSection(),
          ],
        ),
      ),
    );
  }
}

class EraDetailScreen extends StatelessWidget {
  const EraDetailScreen({super.key, required this.eraId});

  final String eraId;

  @override
  Widget build(BuildContext context) {
    final era = HomeContent.eraById(eraId);
    if (era == null) {
      return Scaffold(
        appBar: AppBar(
          leading: appBarLeading(context),
          title: const Text('资料'),
        ),
        body: const ReadingWidth(child: Center(child: Text('没有这一节'))),
      );
    }

    final events = HomeContent.eventsFor(era);
    final terms = HomeContent.termsFor(era);
    final flows = HomeContent.flowsFor(era);
    final scams = HomeContent.scamsFor(era);
    final checklist = HomeContent.checklistFor(era);

    return Scaffold(
      appBar: AppBar(leading: appBarLeading(context), title: Text(era.when)),
      body: ReadingWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(era.title, style: Theme.of(context).textTheme.headlineSmall),
            if (era.besidePath != null) ...[
              const SizedBox(height: 8),
              Text(
                '配合路径「${era.besidePath}」阅读，不代替那一节课或练习。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (era.stablecoin) ...[
              const SizedBox(height: 16),
              for (final paragraph in HomeContent.stablecoinParagraphs) ...[
                Text(paragraph, style: const TextStyle(height: 1.6)),
                const SizedBox(height: 12),
              ],
            ],
            if (era.id == 'new_coins') ...[
              const SizedBox(height: 16),
              Text(
                HomeContent.shitcoinLifecycleTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (
                var i = 0;
                i < HomeContent.shitcoinLifecycleSteps.length;
                i++
              )
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${i + 1}. ${HomeContent.shitcoinLifecycleSteps[i]}',
                  ),
                ),
              const SizedBox(height: 8),
              const _RhetoricMarks(),
              const SizedBox(height: 24),
              const _AnotherBetCard(),
            ],
            if (events.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('当时发生了什么', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final event in events)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.yearMonth} · ${HomeContent.timelineTypeLabel(event.type)}',
                  ),
                ),
            ],
            if (terms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('概念', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final term in terms)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('${term.term}：${term.definition}'),
                ),
            ],
            for (final flow in flows) ...[
              const SizedBox(height: 8),
              Text(flow.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (var i = 0; i < flow.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${i + 1}. ${flow.steps[i]}'),
                ),
            ],
            if (checklist.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('当时要记住的', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final item in checklist)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('${item.shortTitle}：${item.detail}'),
                ),
            ],
            if (scams.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('后来被怎么用', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final scam in scams)
                Card(
                  child: ListTile(
                    contentPadding: chevronTilePadding,
                    title: Text(scam.title),
                    subtitle: Text(scam.summary),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/learn/fraud?scam=${scam.id}'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RhetoricMarks extends StatelessWidget {
  const _RhetoricMarks();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final phrase in HomeContent.rhetoricPhrases)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('「$phrase」：${HomeContent.rhetoricLabels.join(' · ')}'),
          ),
      ],
    );
  }
}

class _AnotherBetCard extends StatelessWidget {
  const _AnotherBetCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(HomeContent.anotherBetLine),
      ),
    );
  }
}
