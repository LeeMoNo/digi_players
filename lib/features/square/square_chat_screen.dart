// lib/features/square/square_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'square_provider.dart';
import 'square_repository.dart';

class SquareChatScreen extends ConsumerStatefulWidget {
  final String room;
  final String roomName;

  const SquareChatScreen({
    super.key,
    required this.room,
    required this.roomName,
  });

  @override
  ConsumerState<SquareChatScreen> createState() =>
      _SquareChatScreenState();
}

class _SquareChatScreenState
    extends ConsumerState<SquareChatScreen> {
  final _inputCtrl   = TextEditingController();
  final _scrollCtrl  = ScrollController();
  bool _sending      = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    // 离开时断开连接
    ref.read(squareRepoProvider).disconnect();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    ref.read(squareRepoProvider).send(text);
    _inputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
        squareMessagesProvider(widget.room));
    final connAsync = ref.watch(
        squareConnStateProvider(widget.room));
    final myDIDAsync = ref.watch(myDIDProvider);
    final myDID = myDIDAsync.value;

    // 新消息到来时滚到底部
    ref.listen(squareMessagesProvider(widget.room), (_, __) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          // 连接状态指示器
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: connAsync.when(
              data: (state) => _ConnIndicator(state: state),
              loading: () => const _ConnIndicator(
                  state: ConnState.connecting),
              error: (_, __) => const _ConnIndicator(
                  state: ConnState.error),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 消息列表 ──────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('连接失败：$e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('暂无消息，来说第一句话吧',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.did == myDID;
                    return _MessageBubble(
                        msg: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // ── 输入栏 ────────────────────────────────
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    maxLength:  500,
                    maxLines:   null,
                    decoration: InputDecoration(
                      hintText:    '说点什么…',
                      counterText: '',
                      filled:      true,
                      fillColor:   Theme.of(context)
                          .colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 消息气泡 ───────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final SquareMessage msg;
  final bool isMe;

  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // 系统消息
    if (msg.type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(msg.body,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _Avatar(name: msg.name ?? '?'),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 4, bottom: 2),
                    child: Text(
                      msg.name ?? _shortDID(msg.did ?? ''),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    msg.body,
                    style: TextStyle(
                      color: isMe ? Colors.white : null,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 2, left: 4, right: 4),
                  child: Text(
                    _formatTime(msg.time),
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            _Avatar(name: '我', isMe: true),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _shortDID(String did) {
    if (did.length < 12) return did;
    return '${did.substring(0, 8)}…';
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final bool isMe;
  const _Avatar({required this.name, this.isMe = false});
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isMe
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── 连接状态指示器 ─────────────────────────────────────

class _ConnIndicator extends StatelessWidget {
  final ConnState state;
  const _ConnIndicator({required this.state});
  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      ConnState.connected    => (Colors.green,  '已连接'),
      ConnState.connecting   => (Colors.orange, '连接中'),
      ConnState.disconnected => (Colors.grey,   '已断开'),
      ConnState.error        => (Colors.red,    '重连中'),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
            color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(fontSize: 12, color: color)),
    ]);
  }
}