import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong2.dart';
import 'package:customer_app/core/socket/socket_client.dart';

class TrackingState {
  final LatLng? technicianLocation;
  final String eta;
  final String status;

  const TrackingState({
    this.technicianLocation,
    this.eta = 'Calculating...',
    this.status = 'Assigning technician',
  });
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  final String _bookingId;
  final SocketClient _socket = SocketClient();
  StreamSubscription? _subscription;

  TrackingNotifier(this._bookingId) : super(const TrackingState()) {
    _initSocket();
  }

  void _initSocket() async {
    await _socket.connect();
    _socket.joinBookingRoom(_bookingId);

    _subscription = _socket.locationStream.listen((data) {
      if (data['bookingId'] == _bookingId) {
        final lat = data['latitude'] as num? ?? data['lat'] as num?;
        final lng = data['longitude'] as num? ?? data['lng'] as num?;
        final eta = data['eta'] as String? ?? 'Calculating...';
        final status = data['status'] as String? ?? 'en-route';

        if (lat != null && lng != null) {
          state = TrackingState(
            technicianLocation: LatLng(lat.toDouble(), lng.toDouble()),
            eta: eta,
            status: status,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _socket.leaveBookingRoom(_bookingId);
    super.dispose();
  }
}

final trackingProvider = StateNotifierProvider.family.autoDispose<TrackingNotifier, TrackingState, String>((ref, bookingId) {
  return TrackingNotifier(bookingId);
});
