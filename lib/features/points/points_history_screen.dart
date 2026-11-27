import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/layout/reading_width.dart';
import '../../core/router/app_back_button.dart';
import '../../core/ui/user_facing_error.dart';

class PointsHistoryItem {
  const PointsHistoryItem({
    required this.id,
    required this.actionKey,
    required this.points,
    required this.createdAt,
  });

  final int id;
  final String actionKey;
  final int points;
  final DateTime createdAt;

  factory PointsHistoryItem.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    return PointsHistoryItem(
      id: (json['id'] as num).toInt(),
      actionKey: json['action_key']?.toString() ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (created as num?)?.toInt() ?? 0,
      ),
    );
  }
}

class PointsHistoryPage {
  const PointsHistoryPage({required this.items, required this.hasMore});

  final List<PointsHistoryItem> items;
  final bool hasMore;
}

/// 把 action_key 翻成用户能看懂的标题。
String pointsActionTitle(String actionKey) {
  switch (actionKey) {
    case 'did_created':
      return '创建身份';
    case 'daily_login':
      return '每日登录';
    case 'daily_quiz':
      return '每日测验';
    case 'lesson_read':
      return '阅读学习卡片';
    case 'lesson_quiz_pass':
      return '通过章节测验';
    case 'chapter_complete':
      return '完成章节';
    case 'totp_enable':
      return '开启二次验证';
    case 'game_hash_complete':
      return '哈希碰碰乐 · 第1关';
    case 'game_hash_level_2':
      return '哈希碰碰乐 · 第2关';
    case 'game_hash_level_3':
      return '哈希碰碰乐 · 第3关';
    case 'game_block_complete':
      return '完成积木练习';
    case 'game_antiscam_complete':
      return '完成防骗练习';
    case 'game_p2p_complete':
      return '完成节点传信练习';
    case 'game_approve_complete':
      return '完成授权雷达练习';
    case 'game_stablecoin_complete':
      return '完成稳定币天平练习';
    case 'game_custody_complete':
      return '完成钥匙归属练习';
    case 'game_multisig_complete':
      return '完成多签核对练习';
    case 'game_listing_complete':
      return '完成牌照与上下架练习';
    default:
      return actionKey.isEmpty ? '积分记录' : actionKey;
  }
}

class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({super.key, this.loadPage});

  final Future<PointsHistoryPage> Function({int? before})? loadPage;

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  final _items = <PointsHistoryItem>[];
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await (widget.loadPage ?? _loadPage)();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = UserFacingError.loadFailed;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _items.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final before = _items.last.createdAt.millisecondsSinceEpoch;
      final page = await (widget.loadPage ?? _loadPage)(before: before);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(UserFacingError.loadFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: const Text('积分记录'),
      ),
      body: ReadingWidth(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Text(_error!, textAlign: TextAlign.center),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Text(
            '还没有积分记录。\n去学习、练习或每日登录，就会出现在这里。',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.5, color: Colors.grey),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 240) {
          _loadMore();
        }
        return false;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
          final item = _items[index];
          final scheme = Theme.of(context).colorScheme;
          // onTap 让 ListTile 启用 Material 涟漪，避免点按毫无反馈
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            onTap: () {},
            title: Text(pointsActionTitle(item.actionKey)),
            subtitle: Text(
              _formatTime(item.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
            trailing: Text(
              '+${item.points}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final local = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

Future<PointsHistoryPage> _loadPage({int? before}) async {
  try {
    final res = await ApiClient.dio.get(
      '/points/history',
      queryParameters: {'limit': 50, if (before != null) 'before': before},
    );
    final data = res.data;
    if (data is! Map) throw Exception('响应无效');
    final raw = data['items'];
    if (raw is! List) throw Exception('响应无效');
    return PointsHistoryPage(
      items: raw
          .whereType<Map>()
          .map(
            (item) =>
                PointsHistoryItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      hasMore: data['has_more'] == true,
    );
  } on DioException catch (e) {
    throw Exception(UserFacingError.from(e, fallback: UserFacingError.network));
  }
}
