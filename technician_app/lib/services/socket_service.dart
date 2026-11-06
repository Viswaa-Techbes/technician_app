import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/network/api_config.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../providers/job_providers.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final session = ref.watch(authProvider);
  final service = SocketService(ref);
  if (session != null) {
    service.connect(session.id, session.role.name);
  }
  ref.onDispose(() => service.disconnect());
  return service;
});

class SocketService {
  final Ref _ref;
  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  SocketService(this._ref);

  void connect(String userId, String role) {
    if (_socket != null && _socket!.connected) return;

    try {
      _socket = io.io(
        ApiConfig.baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        debugPrint('[TechnicianSocket] Connected to backend real-time gateway');
        _socket!.emit('join', userId);
        if (role == 'manager' || role == 'admin') {
          _socket!.emit('join_admin');
        }
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('[TechnicianSocket] Disconnected from backend');
      });

      _socket!.on('jobStatusUpdated', (data) {
        debugPrint('[TechnicianSocket] Real-time jobStatusUpdated: $data');
        _ref.invalidate(jobsProvider(null));
      });

      _socket!.on('bookingStatusUpdated', (data) {
        debugPrint('[TechnicianSocket] Real-time bookingStatusUpdated: $data');
        _ref.invalidate(jobsProvider(null));
      });

      _socket!.on('newJobRequest', (data) {
        debugPrint('[TechnicianSocket] New job request received: $data');
        _ref.invalidate(jobsProvider(null));
      });

      _socket!.on('bookingAssigned', (data) {
        debugPrint('[TechnicianSocket] Booking assigned: $data');
        _ref.invalidate(jobsProvider(null));
      });
    } catch (e) {
      debugPrint('[TechnicianSocket] Socket connection error: $e');
    }
  }

  void updateLocation({
    required String userId,
    required double lat,
    required double lng,
    String? name,
    String? availabilityStatus,
  }) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('update_location', {
        'userId': userId,
        'lat': lat,
        'lng': lng,
        'name': name ?? 'Technician',
        'availabilityStatus': availabilityStatus ?? 'ONLINE',
      });
    }
  }

  void updateAvailability(String userId, String status) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('update_availability', {
        'userId': userId,
        'status': status,
      });
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
