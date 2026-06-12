import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/chapter.dart';
import '../home/daily_task_card.dart';
import '../home/data/home_content.dart';
import '../home/widgets/home_widgets.dart';
import 'learn_repository.dart';

class LearnHomeScreen extends StatefulWidget {
  const LearnHomeScreen({super.key});
  @override State<LearnHomeScreen> createState() => _State();
}

class _State extends State<LearnHomeScreen> {
  final _repo = LearnRepository();
  List<ChapterSummary>? _chapters;
  Set<String> _completed = {};
  final _lang = 'zh_CN';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chapters = await _repo.fetchChaptersList();
    final completed = <String>{};
    for (final c in chapters) {
      if (await _repo.isChapterCompleted(c.chapterId)) {
        completed.add(c.chapterId);
      }
    }
    if (mounted) {
      setState(() {
        _chapters = chapters;
        _completed = completed;
      });
    }
  }

  bool _unlocked(ChapterSummary c) =>
      c.requiresChapter.isEmpty || _completed.contains(c.requiresChapter);

  Widget _buildChapterTile(ChapterSummary c) {
    final unlocked = _unlocked(c);
    final completed = _completed.contains(c.chapterId);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: completed
              ? Colors.green
              : unlocked
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
          child: Icon(
            completed ? Icons.check : unlocked ? Icons.book : Icons.lock,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          c.localTitle(_lang),
          style: TextStyle(
            color: unlocked ? null : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          unlocked ? c.localDesc(_lang) : '完成前置章节后解锁',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: unlocked
            ? const Icon(Icons.chevron_right)
            : const Icon(Icons.lock_outline, color: Colors.grey),
        onTap: unlocked
            ? () => context.push('/learn/chapter/${c.chapterId}')
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习')),
      body: ListView(
        children: [
          const DailyTaskCard(),
          if (_chapters == null)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    HomeContent.tagline,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  const FraudSummarySection(),
                  const SizedBox(height: 32),
                  const TimelineSection(),
                  const SizedBox(height: 32),
                  const GlossarySection(),
                  const SizedBox(height: 32),
                  const FlowOverviewSection(),
                  const SizedBox(height: 32),
                  const LearnMapSection(),
                  const SizedBox(height: 32),
                  const ExternalLinksSection(),
                  const SizedBox(height: 32),
                  Text(
                    '学程章节',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (_chapters!.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('暂无章节内容')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _chapters!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _buildChapterTile(_chapters![i]),
              ),
          ],
        ],
      ),
    );
  }
}
