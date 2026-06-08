// lib/features/square/square_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage.dart';
import 'square_repository.dart';

// 全局唯一 Repository 实例
final squareRepoProvider = Provider<SquareRepository>((ref) {
  final repo = SquareRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

// 当前用户 DID（用于标记自己的消息）
final myDIDProvider = FutureProvider<String?>((ref) async {
  return SecureStorage.getDID();
});

// 消息流
final squareMessagesProvider =
    StreamProvider.family<List<SquareMessage>, String>((ref, room) {
  final repo = ref.watch(squareRepoProvider);
  repo.connect(room);
  return repo.messageStream ?? const Stream.empty();
});

// 连接状态流
final squareConnStateProvider =
    StreamProvider.family<ConnState, String>((ref, room) {
  final repo = ref.watch(squareRepoProvider);
  return repo.stateStream ?? const Stream.empty();
});