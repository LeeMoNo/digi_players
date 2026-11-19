import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_route_observer.dart';
import '../home/daily_task_card.dart';
import '../home/data/home_content.dart';
import 'learn_path.dart';
import 'learn_repository.dart';

class LearnHomeScreen extends StatefulWidget {
  const LearnHomeScreen({
    super.key,
    this.loadChapters,
    this.loadProgress,
    this.dailyTask = const DailyTaskCard(),
  });

  /// 拉取章节列表。失败时继续卡改为重试。测试可替换。
  final Future<void> Function()? loadChapters;

  /// 读取六步进度。测试可替换。
  final Future<LearnPathProgress> Function()? loadProgress;

  final Widget dailyTask;

  @override
  State<LearnHomeScreen> createState() => _LearnHomeScreenState();
}

class _LearnHomeScreenState extends State<LearnHomeScreen> with RouteAware {
  final _repo = LearnRepository();
  LearnPathProgress _progress = const LearnPathProgress();
  bool _loadingChapters = true;
  bool _chaptersReady = false;
  bool _chaptersFailed = false;
  ModalRoute<void>? _route;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      if (_route != null) appRouteObserver.unsubscribe(this);
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _load();
  }

  Future<void> _load() async {
    final progress = await (widget.loadProgress ?? readLearnPathProgress)();
    if (!mounted) return;
    setState(() => _progress = progress);

    try {
      final load = widget.loadChapters ??
          () async {
            await _repo.fetchChaptersList();
          };
      await load();
      if (!mounted) return;
      setState(() {
        _chaptersReady = true;
        _chaptersFailed = false;
        _loadingChapters = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingChapters = false;
        if (!_chaptersReady) _chaptersFailed = true;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loadingChapters = true;
      _chaptersFailed = false;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final step = nextLearnStep(_progress);
    final catalog = learnCatalog(_progress);

    return Scaffold(
      appBar: AppBar(title: const Text('学习')),
      body: ListView(
        key: const Key('learn-home-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _ContinueCard(
            loading: _loadingChapters && !_chaptersReady,
            failed: _chaptersFailed,
            step: step,
            onRetry: _retry,
          ),
          const SizedBox(height: 12),
          widget.dailyTask,
          const SizedBox(height: 20),
          Text('路径', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in catalog) ...[
            _CatalogTile(item: item),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('资料'),
              subtitle: const Text('年史、术语、防骗与外链'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/learn/library'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.loading,
    required this.failed,
    required this.step,
    required this.onRetry,
  });

  final bool loading;
  final bool failed;
  final LearnPathStep step;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final title = failed
        ? '章节暂时取不到'
        : loading
            ? '继续'
            : step.title;
    final button = failed ? '重试' : step.button;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              key: const Key('continue-title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (loading)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('正在读取章节'),
                ],
              )
            else
              FilledButton(
                key: const Key('continue-button'),
                onPressed: failed
                    ? () => onRetry()
                    : () => context.push(step.route),
                child: Text(button),
              ),
          ],
        ),
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({required this.item});

  final LearnCatalogItem item;

  @override
  Widget build(BuildContext context) {
    final open = item.done || item.current;
    final subtitle = item.done
        ? '已完成'
        : item.current
            ? '进行到这里'
            : '稍后解锁';
    final era = item.readingEraId == null
        ? null
        : HomeContent.eraById(item.readingEraId!);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              item.done
                  ? Icons.check_circle
                  : item.current
                      ? Icons.play_circle_outline
                      : Icons.lock_outline,
            ),
            title: Text(item.title),
            subtitle: Text(subtitle),
            trailing: open ? const Icon(Icons.chevron_right) : null,
            onTap: open ? () => context.push(item.route) : null,
          ),
          if (era != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push('/learn/library/${era.id}'),
                child: Text('相关资料 · ${era.title}'),
              ),
            ),
        ],
      ),
    );
  }
}
