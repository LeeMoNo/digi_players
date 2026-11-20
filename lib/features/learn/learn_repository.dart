import 'package:hive_flutter/hive_flutter.dart';
import '../../core/api/api_client.dart';
import '../../core/models/chapter.dart';
import '../../core/progress/progress_store.dart';
import '../../core/utils/json_map.dart';

class LearnRepository {
  static const _box = 'learn_progress';

  Future<List<ChapterSummary>> fetchChaptersList() async {
    final res = await ApiClient.dio.get('/content/chapters');
    return (res.data['chapters'] as List)
        .map((j) => ChapterSummary.fromJson(j))
        .toList();
  }

  Future<ChapterDetail> fetchChapterDetail(String chapterId) async {
    final box = await Hive.openBox(_box);
    final cache = box.get('chapter_json_$chapterId');
    if (cache != null) {
      return ChapterDetail.fromJson(deepJsonMap(cache));
    }
    final res = await ApiClient.dio.get('/content/chapter/$chapterId');
    final json = deepJsonMap(res.data);
    await box.put('chapter_json_$chapterId', json);
    return ChapterDetail.fromJson(json);
  }

  Future<Set<String>> getReadCards() => ProgressStore.readCards();

  Future<void> markCardRead(String cardId) => ProgressStore.markCard(cardId);

  Future<bool> isChapterCompleted(String id) =>
      ProgressStore.hasFlag('completed_$id');

  Future<void> markChapterCompleted(String id) =>
      ProgressStore.markFlag('completed_$id');

  Future<void> awardPoints(String actionKey) async {
    try {
      await ApiClient.dio.post(
        '/points/award',
        data: {'action_key': actionKey},
      );
    } catch (_) {
      // 积分上报失败不影响学习体验
    }
  }
}
