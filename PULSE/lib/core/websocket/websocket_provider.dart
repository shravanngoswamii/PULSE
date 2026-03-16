import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'websocket_client.dart';

final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  return WebSocketClient();
});

final webSocketEventsProvider = StreamProvider<dynamic>((ref) {
  final client = ref.watch(webSocketClientProvider);
  return client.events;
});
