import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../features/auth/presentation/providers/auth_provider.dart';

import '../core/network/api_config.dart';
import '../providers/job_providers.dart';
import '../providers/live_technicians_provider.dart';
import '../features/attendance/presentation/providers/attendance_provider.dart';

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
      debugPrint('[RealtimeService] Connected');
      _socket?.emit('join', session.id);
    });

    _socket?.on('notification', (data) {
      debugPrint('[RealtimeService] New Notification: $data');
    });

    _socket?.on('refresh_data', (data) {
      debugPrint('[RealtimeService] Refreshing data: $data');
      final type = data['type'];
      if (type == 'status_update' || type == 'job_assigned' || type == 'payment_completed') {
        _ref.invalidate(jobsProvider);
      }
      if (type == 'location_update') {
        _ref.invalidate(liveTechniciansProvider);
      }
    });

    _socket?.on('attendance_updated', (data) {
      debugPrint('[RealtimeService] Attendance updated: $data');
      _ref.invalidate(attendanceProvider);
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
