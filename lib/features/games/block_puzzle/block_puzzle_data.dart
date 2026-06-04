// lib/features/games/block_puzzle/block_puzzle_data.dart

class PuzzleBlock {
  final String id;
  final String prevHash;      // 本块声称的前块哈希
  final String ownHash;       // 本块的哈希（作为下一块的 prevHash）
  final String txData;        // 当前显示的交易数据（可能被篡改）
  final String correctTxData; // 正确的交易数据
  final int nonce;
  final bool isTampered;

  const PuzzleBlock({
    required this.id,
    required this.prevHash,
    required this.ownHash,
    required this.txData,
    required this.correctTxData,
    required this.nonce,
    this.isTampered = false,
  });

  bool get isCorrect => txData == correctTxData;
}

// ── 正确的链（顺序 0→1→2→3→4）────────────────────────

const _genesisHash = '0000000000000000';

final correctChain = [
  PuzzleBlock(
    id: 'blk_0',
    prevHash: _genesisHash,
    ownHash: 'a3f8c2d1e4b59067',
    txData: 'Alice → Bob : 1.0 BTC',
    correctTxData: 'Alice → Bob : 1.0 BTC',
    nonce: 48291,
  ),
  PuzzleBlock(
    id: 'blk_1',
    prevHash: 'a3f8c2d1e4b59067',
    ownHash: '9b2e7f4a1c836d50',
    txData: 'Charlie → Dave : 0.5 ETH',   // ← 被篡改（原是 0.5 BTC）
    correctTxData: 'Charlie → Dave : 0.5 BTC',
    nonce: 91047,
    isTampered: true,
  ),
  PuzzleBlock(
    id: 'blk_2',
    prevHash: '9b2e7f4a1c836d50',
    ownHash: 'f1d4a8e2c7b30956',
    txData: 'Eve → Frank : 2.0 BTC',
    correctTxData: 'Eve → Frank : 2.0 BTC',
    nonce: 23718,
  ),
  PuzzleBlock(
    id: 'blk_3',
    prevHash: 'f1d4a8e2c7b30956',
    ownHash: '4c9e1b7d2a658f30',
    txData: 'Grace → Henry : 100 USDT',   // ← 被篡改（原是 10 USDT）
    correctTxData: 'Grace → Henry : 10 USDT',
    nonce: 67392,
    isTampered: true,
  ),
  PuzzleBlock(
    id: 'blk_4',
    prevHash: '4c9e1b7d2a658f30',
    ownHash: '7e3a5f0c9d1b4286',
    txData: 'Ivan → Judy : 0.1 BTC',
    correctTxData: 'Ivan → Judy : 0.1 BTC',
    nonce: 11204,
  ),
];

// 游戏开始时打乱顺序
List<PuzzleBlock> buildScrambledBlocks() {
  final list = List<PuzzleBlock>.from(correctChain);
  list.shuffle();
  return list;
}

// 验证当前排列是否正确
bool validateChainOrder(List<PuzzleBlock> blocks) {
  if (blocks[0].prevHash != _genesisHash) return false;
  for (int i = 1; i < blocks.length; i++) {
    if (blocks[i].prevHash != blocks[i - 1].ownHash) return false;
  }
  return true;
}