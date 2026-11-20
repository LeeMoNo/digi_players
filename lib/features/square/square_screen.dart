// lib/features/square/square_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/display_name.dart';
import '../../core/layout/reading_width.dart';
import '../../core/layout/window_layout_host.dart';
import '../../core/storage/secure_storage.dart';

class SquareScreen extends StatefulWidget {
  const SquareScreen({super.key, this.selectedRoomId});

  final String? selectedRoomId;

  @override
  State<SquareScreen> createState() => _State();
}

class _State extends State<SquareScreen> {
  String? _did;
  String _name = fallbackDisplayName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final did = await SecureStorage.getDID();
    var name = fallbackDisplayName;
    try {
      final res = await ApiClient.dio.get('/user/profile');
      name = displayNameOrFallback(res.data['display_name'] as String?);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _did = did;
      _name = name;
    });
  }

  String _shortDID(String did) {
    if (did.length <= 18) return did;
    return '${did.substring(0, 14)}...${did.substring(did.length - 6)}';
  }

  void _openRoom(BuildContext context, _RoomConfig room) {
    if (room.id == widget.selectedRoomId) return;
    final location = '/square/chat/${room.id}';
    if (!WindowLayoutScope.layoutOf(context).canSplit) {
      context.push(location, extra: room.name);
      return;
    }
    if (widget.selectedRoomId != null) {
      context.pushReplacement(location, extra: room.name);
    } else {
      context.push(location, extra: room.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数民广场')),
      body: ReadingWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 身份展示
            if (_did != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.12),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fingerprint, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _shortDID(_did!),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const Text(
              '选择话题',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            for (final room in _rooms)
              _RoomTile(
                room: room,
                selected: room.id == widget.selectedRoomId,
                onTap: () => _openRoom(context, room),
              ),
          ],
        ),
      ),
    );
  }
}

// 房间配置
class _RoomConfig {
  final String id, name, description;
  final IconData icon;
  final Color color;
  const _RoomConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const _rooms = [
  _RoomConfig(
    id: 'blockchain',
    name: '区块链技术',
    description: 'Layer2、共识机制、跨链桥',
    icon: Icons.hub,
    color: Colors.teal,
  ),
  _RoomConfig(
    id: 'cryptography',
    name: '密码学讨论',
    description: 'ZKP、MPC、同态加密',
    icon: Icons.lock,
    color: Colors.indigo,
  ),
  _RoomConfig(
    id: 'did',
    name: 'DID 与 Web3 身份',
    description: 'VC、SSI、去中心化登录',
    icon: Icons.badge,
    color: Colors.purple,
  ),
  _RoomConfig(
    id: 'antiscam',
    name: '反诈经验交流',
    description: '识骗手册、案例分析',
    icon: Icons.security,
    color: Colors.orange,
  ),
];

class _RoomTile extends StatelessWidget {
  final _RoomConfig room;
  final bool selected;
  final VoidCallback onTap;
  const _RoomTile({
    required this.room,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      selected: selected,
      contentPadding: const EdgeInsets.all(14),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: room.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(room.icon, color: room.color, size: 24),
      ),
      title: Text(
        room.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(room.description, style: const TextStyle(fontSize: 12)),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
