import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:customer_app/core/config/env_config.dart';
import 'package:customer_app/core/storage/secure_storage.dart';
import 'package:customer_app/core/notifications/notification_service.dart';

class SocketClient {
  static final SocketClient _instance = SocketClient._internal();
  factory SocketClient() => _instance;

  SocketClient._internal();

  io.Socket? _socket;
  final _locationController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({String? userId}) async {
    if (_socket != null && _socket!.connected) {
      if (userId != null) {
        _socket!.emit('join', userId);
      }
      return;
    }

    final token = await SecureStorage.getToken();
    final socketUrl = EnvConfig.apiBaseUrl;

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders(token != null ? {'Authorization': 'Bearer $token'} : {})
          .build(),
    );

    _socket!.onConnect((_) {
      if (kDebugMode) print('Socket connected to $socketUrl');
      if (userId != null) {
        _socket!.emit('join', userId);
      }
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) print('Socket disconnected');
    });

    _socket!.onConnectError((err) {
      if (kDebugMode) print('Socket connect error: $err');
    });

    _socket!.on('technician-location', (data) {
      if (kDebugMode) print('Socket technician-location event: $data');
      if (data is Map) {
        _locationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('notification', (data) {
      if (kDebugMode) print('Socket notification event: $data');
      if (data is Map) {
        final title = data['title'] ?? 'New Notification';
        final body = data['message'] ?? '';
        final id = data['id']?.hashCode ?? DateTime.now().millisecondsSinceEpoch.hashCode;
        NotificationService().showNotification(
          id: id,
          title: title,
          body: body,
        );
      }
    });

    _socket!.connect();
  }

  void joinBookingRoom(String bookingId) {
    if (_socket == null || !_socket!.connected) return;
    if (kDebugMode) print('Socket joining booking room: $bookingId');
    _socket!.emit('join-booking-room', {'bookingId': bookingId});
  }

  void leaveBookingRoom(String bookingId) {
    if (_socket == null || !_socket!.connected) return;
    if (kDebugMode) print('Socket leaving booking room: $bookingId');
    _socket!.emit('leave-booking-room', {'bookingId': bookingId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
