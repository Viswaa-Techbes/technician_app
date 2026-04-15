import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../features/auth/presentation/providers/auth_provider.dart';

import '../core/network/api_config.dart';

class RealtimeService {
  final String baseUrl = ApiConfig.baseUrl; 
  io.Socket? _socket;
  final Ref _ref;

  RealtimeService(this._ref);

  void connect() {
    final session = _ref.read(authProvider);
    if (session == null) return;

    _socket = io.io(baseUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setExtraHeaders({'Authorization': 'Bearer ${session.token}'})
      .build());

    _socket?.onConnect((_) {
      debugPrint('Realtime Connected');
      _socket?.emit('join', session.id);
    });

    _socket?.on('notification', (data) {
      debugPrint('New Notification: $data');
      // Potential to use a Notifier to update a list of notifications
    });

    _socket?.connect();
  }

  void updateLocation(double lat, double lng) {
    final session = _ref.read(authProvider);
    if (session != null && _socket?.connected == true) {
      _socket?.emit('update_location', {
        'userId': session.id,
        'name': session.name,
        'lat': lat,
        'lng': lng,
      });
    }
  }

  void dispose() {
    _socket?.dispose();
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
