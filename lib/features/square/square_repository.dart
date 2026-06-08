// lib/features/square/square_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/storage/secure_storage.dart';

enum ConnState { disconnected, connecting, connected, error }

class SquareMessage {
  final String type;   // 'message' | 'system' | 'history' | 'error'
  final String? did;
  final String? name;
  final String body;
  final DateTime time;

  const SquareMessage({
    required this.type,
    this.did,
    this.name,
    required this.body,
    required this.time,
  });

  factory SquareMessage.fromJson(Map<String, dynamic> j) =>
      SquareMessage(
        type: j['type'] as String,
        did:  j['did']  as String?,
        name: j['name'] as String?,
        body: j['body'] as String? ?? '',
        time: DateTime.fromMillisecondsSinceEpoch(
            (j['ts'] as int?) ?? 0),
      );

  bool get isMe => false; // 由外部传入 myDID 比较
}

class SquareRepository {
  static const _baseWsUrl = String.fromEnvironment(
    'WORKERS_WS_URL',
    defaultValue: 'wss://digiplayers-workers.你的账号.workers.dev',
  );

  WebSocketChannel? _channel;
  StreamController<List<SquareMessage>>? _msgCtrl;
  StreamController<ConnState>? _stateCtrl;
  Timer? _reconnectTimer;

  String? _currentRoom;
  int _reconnectDelay = 2; // 秒，指数退避

  Stream<List<SquareMessage>>? get messageStream => _msgCtrl?.stream;
  Stream<ConnState>? get stateStream => _stateCtrl?.stream;

  final List<SquareMessage> _messages = [];

  Future<void> connect(String room) async {
    _currentRoom = room;
    _msgCtrl  ??= StreamController<List<SquareMessage>>.broadcast();
    _stateCtrl ??= StreamController<ConnState>.broadcast();

    _stateCtrl!.add(ConnState.connecting);

    final jwt = await SecureStorage.getJWT();
    if (jwt == null) {
      _stateCtrl!.add(ConnState.error);
      return;
    }

    final uri = Uri.parse(
      '$_baseWsUrl/square/ws?room=$room&token=$jwt',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _stateCtrl!.add(ConnState.connected);
      _reconnectDelay = 2; // 成功后重置退避

      _channel!.stream.listen(
        _onMessage,
        onDone:  _onDisconnected,
        onError: _onError,
        cancelOnError: false,
      );
    } catch (e) {
      _stateCtrl!.add(ConnState.error);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;

      if (data['type'] == 'history') {
        final list = (data['messages'] as List)
            .map((m) => SquareMessage.fromJson(m))
            .toList();
        _messages
          ..clear()
          ..addAll(list);
      } else {
        final msg = SquareMessage.fromJson(data);
        _messages.add(msg);
        if (_messages.length > 100) _messages.removeAt(0);
      }

      _msgCtrl!.add(List.unmodifiable(_messages));
    } catch (_) {}
  }

  void _onDisconnected() {
    _stateCtrl?.add(ConnState.disconnected);
    _scheduleReconnect();
  }

  void _onError(dynamic _) {
    _stateCtrl?.add(ConnState.error);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: _reconnectDelay),
      () { if (_currentRoom != null) connect(_currentRoom!); },
    );
    _reconnectDelay = (_reconnectDelay * 2).clamp(2, 30);
  }

  void send(String body) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'message',
      'body': body,
    }));
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel     = null;
    _currentRoom = null;
    _messages.clear();
  }

  void dispose() {
    disconnect();
    _msgCtrl?.close();
    _stateCtrl?.close();
  }
}