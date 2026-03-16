import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import 'dart:async';

class PulseWebSocket {
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    // Stub definition
    _isConnected = true;
  }

  void disconnect() {
    _isConnected = false;
  }

  void send(String event, Map<String, dynamic> data) {
    if (!_isConnected) return;
    // Stub
  }

  Stream<Map<String, dynamic>> onEvent(String event) async* {
    // Stub
    yield {};
  }
}

final websocketProvider = Provider<PulseWebSocket>((ref) {
  return PulseWebSocket();
});
