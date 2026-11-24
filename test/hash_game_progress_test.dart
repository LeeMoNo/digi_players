import 'dart:io';

import 'package:digi_players/features/games/hash_game/hash_game_progress.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('hash_game_progress_');
    Hive.init(hiveDir.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            if (call.method == 'read' &&
                (call.arguments as Map)['key'] == 'dp_did') {
              return 'did:test:hash';
            }
            return null;
          },
        );
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          null,
        );
  });

  test('normalize：非法关卡回到第一关', () {
    expect(
      HashGameProgress.normalize(level: 0, solvedNonces: const []),
      HashGameCheckpoint.start,
    );
    expect(
      HashGameProgress.normalize(level: 3, solvedNonces: const [1, 2, 3]),
      HashGameCheckpoint.start,
    );
    expect(
      HashGameProgress.normalize(level: 1, solvedNonces: const []),
      HashGameCheckpoint.start,
    );
    final ok = HashGameProgress.normalize(level: 1, solvedNonces: const [42]);
    expect(ok.level, 1);
    expect(ok.solvedNonces, [42]);
  });

  test('通关后保存，下次 load 从下一关开始', () async {
    await HashGameProgress.save(
      const HashGameCheckpoint(level: 1, solvedNonces: [12]),
    );

    final loaded = await HashGameProgress.load();
    expect(loaded.level, 1);
    expect(loaded.solvedNonces, [12]);
  });

  test('三关全通后 clear，再进来从第一关开始', () async {
    await HashGameProgress.save(
      const HashGameCheckpoint(level: 2, solvedNonces: [1, 2]),
    );
    await HashGameProgress.clear();

    final loaded = await HashGameProgress.load();
    expect(loaded, HashGameCheckpoint.start);
  });
}
