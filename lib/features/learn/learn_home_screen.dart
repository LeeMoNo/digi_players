import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/chapter.dart';
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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final chapters = await _repo.fetchChaptersList();
    final completed = <String>{};
    for (final c in chapters) {
      if (await _repo.isChapterCompleted(c.chapterId)) completed.add(c.chapterId);
    }
    if (mounted) setState(() { _chapters = chapters; _completed = completed; });
  }

  bool _unlocked(ChapterSummary c) =>
      c.requiresChapter.isEmpty || _completed.contains(c.requiresChapter);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习')),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
          Text('学程章节', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (_chapters == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_chapters!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('暂无章节内容')),
            )
          else
            ...List.generate(_chapters!.length, (i) {
              final c = _chapters![i];
              final unlocked = _unlocked(c);
              final completed = _completed.contains(c.chapterId);
              return Padding(
                padding: EdgeInsets.only(bottom: i < _chapters!.length - 1 ? 12 : 0),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: completed ? Colors.green
                          : unlocked ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      child: Icon(
                        completed ? Icons.check : unlocked ? Icons.book : Icons.lock,
                        color: Colors.white, size: 20,
                      ),
                    ),
                    title: Text(c.localTitle(_lang),
                      style: TextStyle(
                        color: unlocked ? null : Colors.grey,
                        fontWeight: FontWeight.w600,
                      )),
                    subtitle: Text(
                      unlocked ? c.localDesc(_lang) : '完成前置章节后解锁',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    trailing: unlocked
                        ? const Icon(Icons.chevron_right)
                        : const Icon(Icons.lock_outline, color: Colors.grey),
                    onTap: unlocked
                        ? () => context.push('/learn/chapter/${c.chapterId}')
                        : null,
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
