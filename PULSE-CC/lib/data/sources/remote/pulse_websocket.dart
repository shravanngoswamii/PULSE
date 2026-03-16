import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants/api_constants.dart';
import '../local/secure_storage.dart';
import 'dart:async';
import 'dart:convert';

class PulseWebSocket {
  final SecureStorage _storage;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  PulseWebSocket(this._storage);

  bool get isConnected => _isConnected;

  /// Stream of all incoming WebSocket events (parsed JSON maps).
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  Future<void> connect() async {
    if (_isConnected) return;
    _shouldReconnect = true;

    try {
      final token = await _storage.getToken();
      final uri = token != null
          ? Uri.parse('${ApiConstants.wsUrl}?token=$token')
          : Uri.parse(ApiConstants.wsUrl);

      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            _eventController.add(data);
          } catch (_) {
            // Ignore non-JSON messages
          }
        },
        onDone: () {
          _isConnected = false;
          _attemptReconnect();
        },
        onError: (error) {
          _isConnected = false;
          _attemptReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (!_shouldReconnect) return;
    Future.delayed(ApiConstants.wsReconnectDelay, () {
      if (_shouldReconnect) connect();
    });
  }

  void disconnect() {
    _shouldReconnect = false;
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
  }

  void send(String event, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) return;
    final payload = jsonEncode({'event': event, ...data});
    _channel!.sink.add(payload);
  }

  /// Convenience: filter the event stream by event type field.
  Stream<Map<String, dynamic>> onEvent(String event) {
    return _eventController.stream
        .where((data) => data['event'] == event || data['type'] == event);
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}

final websocketProvider = Provider<PulseWebSocket>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final ws = PulseWebSocket(storage);
  ref.onDispose(() => ws.dispose());
  return ws;
});
