import 'package:hive_flutter/hive_flutter.dart';
import '../../core/api/api_client.dart';
import '../../core/models/chapter.dart';

class LearnRepository {
  static const _box = 'learn_progress';

  Future<List<ChapterSummary>> fetchChaptersList() async {
    final res = await ApiClient.dio.get('/content/chapters');
    return (res.data['chapters'] as List)
        .map((j) => ChapterSummary.fromJson(j)).toList();
  }

  Future<ChapterDetail> fetchChapterDetail(String chapterId) async {
    final box   = await Hive.openBox(_box);
    final cache = box.get('chapter_json_$chapterId');
    if (cache != null) return ChapterDetail.fromJson(Map<String, dynamic>.from(cache));
    final res = await ApiClient.dio.get('/content/chapter/$chapterId');
    await box.put('chapter_json_$chapterId', res.data);
    return ChapterDetail.fromJson(res.data);
  }

  Future<Set<String>> getReadCards() async {
    final box = await Hive.openBox(_box);
    return Set<String>.from(box.get('read_cards', defaultValue: []));
  }

  Future<void> markCardRead(String cardId) async {
    final box  = await Hive.openBox(_box);
    final read = Set<String>.from(box.get('read_cards', defaultValue: []));
    read.add(cardId);
    await box.put('read_cards', read.toList());
  }

  Future<bool> isChapterCompleted(String id) async {
    final box = await Hive.openBox(_box);
    return box.get('completed_$id', defaultValue: false);
  }

  Future<void> markChapterCompleted(String id) async {
    final box = await Hive.openBox(_box);
    await box.put('completed_$id', true);
  }

  Future<void> awardPoints(String actionKey) async {
    try {
      await ApiClient.dio.post('/points/award', data: {'action_key': actionKey});
    } catch (_) {
      // 积分上报失败不影响学习体验
    }
  }
}