// lib/features/games/hash_game/hash_game_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/proof_hash.dart';
import 'hash_game_logic.dart';

class HashGameScreen extends StatefulWidget {
  const HashGameScreen({super.key});
  @override State<HashGameScreen> createState() => _State();
}

class _State extends State<HashGameScreen> {
  int    _level     = 0;           // 当前关卡 0/1/2
  int    _nonce     = 0;
  String _hash      = '';
  bool   _levelDone = false;
  bool   _gameDone  = false;
  bool   _loading   = false;
  String? _seed;                   // 服务端签发的 seed

  // 记录每关成功时的 nonce，用于 result_data
  final List<int> _solvedNonces = [];

  @override
  void initState() {
    super.initState();
    _fetchSeed();
    _updateHash();
  }

  // 游戏开始时从服务端拿 seed
  Future<void> _fetchSeed() async {
    try {
      final res = await ApiClient.dio.post('/game/start',
          data: {'action_key': 'game_hash_complete'});
      setState(() => _seed = res.data['seed'] as String);
    } catch (_) {
      // seed 获取失败不阻断游戏，只影响积分上报
    }
  }

  void _updateHash() {
    final txData = HashGameLogic.levels[_level];
    final hash   = HashGameLogic.compute(txData, _nonce);
    final done   = HashGameLogic.meetsDifficulty(
        hash, HashGameLogic.difficulties[_level]);
    setState(() { _hash = hash; _levelDone = done; });
  }

  void _onNonceChanged(double value) {
    _nonce = value.toInt();
    _updateHash();
  }

  void _nextLevel() {
    _solvedNonces.add(_nonce);

    if (_level < HashGameLogic.levels.length - 1) {
      setState(() {
        _level++;
        _nonce     = 0;
        _levelDone = false;
      });
      _updateHash();
    } else {
      // 三关全过，上报积分
      _submitScore();
    }
  }

  Future<void> _submitScore() async {
    setState(() { _loading = true; _gameDone = true; });

    if (_seed == null) {
      setState(() => _loading = false);
      return; // 没有 seed，跳过积分上报
    }

    try {
      final did       = await SecureStorage.getDID() ?? '';
      final resultData = _solvedNonces.join(',');
      final proof     = buildProofHash(
        did:        did,
        actionKey:  'game_hash_complete',
        seed:       _seed!,
        resultData: resultData,
      );

      await ApiClient.dio.post('/points/award', data: {
        'action_key':  'game_hash_complete',
        'proof_hash':  proof,
        'result_data': resultData,
      });
    } catch (_) {
      // 上报失败静默处理
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── 哈希着色：把开头的零变绿色 ────────────────────
  Widget _coloredHash(String hash, int difficulty) {
    final zerosOk   = hash.substring(0, difficulty);
    final remainder = hash.substring(difficulty);
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        children: [
          TextSpan(
            text: zerosOk,
            style: const TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: remainder,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_gameDone) return _buildResult();

    final difficulty = HashGameLogic.difficulties[_level];
    final txData     = HashGameLogic.levels[_level];
    final maxNonce   = 999999.0;

    return Scaffold(
      appBar: AppBar(title: Text('哈希碰碰乐  关卡 ${_level + 1}/3')),
      backgroundColor: const Color(0xFF0F1117),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 目标说明
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('目标：哈希开头出现 $difficulty 个零',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('交易数据：$txData',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12,
                          fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nonce 滑块
            Text('Nonce：$_nonce',
                style: const TextStyle(color: Colors.white70)),
            Slider(
              value: _nonce.toDouble(),
              min: 0,
              max: maxNonce,
              divisions: 999999,
              onChanged: _onNonceChanged,
            ),

            // 手动输入 nonce（方便精确控制）
            TextField(
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '或直接输入 Nonce',
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n >= 0 && n <= 999999) {
                  _nonce = n;
                  _updateHash();
                }
              },
            ),
            const SizedBox(height: 20),

            // 哈希结果显示
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _levelDone ? Colors.green.shade900 : Colors.white10,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _levelDone ? Colors.green : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SHA-256 结果：',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  _coloredHash(_hash, difficulty),
                  if (_levelDone) ...[
                    const SizedBox(height: 8),
                    Row(children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text('满足条件！',
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 提示文字
            Text(HashGameLogic.hint(_level),
                style: const TextStyle(color: Colors.white38, fontSize: 12)),

            const Spacer(),

            if (_levelDone)
              FilledButton(
                onPressed: _nextLevel,
                child: Text(_level < 2 ? '下一关 →' : '完成游戏，领取积分'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.military_tech, color: Colors.amber, size: 80),
              const SizedBox(height: 24),
              const Text('三关全通！',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                '你刚刚体验了真实的挖矿过程。\n'
                '比特币矿工每秒要做数万亿次这样的计算。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.6),
              ),
              if (_loading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ] else ...[
                const SizedBox(height: 12),
                const Text('积分已到账 🎉',
                    style: TextStyle(color: Colors.green)),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/games'),
                child: const Text('返回游戏列表'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}