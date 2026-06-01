// lib/features/square/square_screen.dart
import 'package:flutter/material.dart';
import '../../core/storage/secure_storage.dart';

class SquareScreen extends StatefulWidget {
  const SquareScreen({super.key});
  @override State<SquareScreen> createState() => _State();
}

class _State extends State<SquareScreen> {
  String? _did;

  @override
  void initState() {
    super.initState();
    SecureStorage.getDID().then((d) {
      if (mounted) setState(() => _did = d);
    });
  }

  String _shortDID(String did) {
    if (did.length <= 18) return did;
    return '${did.substring(0, 14)}...${did.substring(did.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数民广场')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 身份展示
            if (_did != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.12),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(children: [
                  const Icon(Icons.fingerprint, size: 36),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('你是一位数字游民',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(_shortDID(_did!),
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.grey)),
                    ],
                  ),
                ]),
              ),
            const SizedBox(height: 28),

            // 建设中提示
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(Icons.construction,
                      size: 56,
                      color: Theme.of(context)
                          .colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('广场正在建设中',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                    'Phase 2 将开放去中心化实时讨论区，\n'
                    '基于 P2P 技术，数字游民们在这里自由交流。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 话题入口占位（框架已在，内容 Phase 2 填充）
            Text('话题分区',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final topic in _topicPlaceholders)
              _TopicPlaceholder(title: topic.$1, desc: topic.$2, icon: topic.$3),
          ],
        ),
      ),
    );
  }
}

const _topicPlaceholders = [
  ('区块链技术', 'Layer2、共识机制、跨链桥', Icons.hub),
  ('密码学讨论', 'ZKP、MPC、同态加密', Icons.lock),
  ('DID 与 Web3 身份', 'VC、SSI、去中心化登录', Icons.badge),
  ('反诈经验交流', '识骗手册、案例分析', Icons.security),
];

class _TopicPlaceholder extends StatelessWidget {
  final String title, desc;
  final IconData icon;
  const _TopicPlaceholder({
    required this.title, required this.desc, required this.icon,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      Icon(icon, size: 22,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(desc,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      Icon(Icons.chevron_right,
          color: Colors.grey.shade300),
    ]),
  );
}