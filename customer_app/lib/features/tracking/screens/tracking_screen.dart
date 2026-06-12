import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';

import 'package:customer_app/core/theme/app_colors.dart';
import 'package:customer_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:customer_app/features/tracking/providers/tracking_provider.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const TrackingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final MapController _mapController = MapController();
  LatLng _destination = const LatLng(12.9716, 77.5946); // Fallback Indiranagar

  @override
  void initState() {
    super.initState();
    // Resolve coordinates from booking data in cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardData = ref.read(dashboardDataProvider).value;
      final matching = dashboardData?.bookings.firstWhere(
        (b) => b.id == widget.bookingId,
        orElse: () => dashboardData.upcomingBookings.firstWhere(
          (b) => b.id == widget.bookingId,
          orElse: () => const MapEntry('id', null) as dynamic,
        ),
      );
      // Try to parse lat/lng or address coords
      if (matching != null && matching.id.isNotEmpty) {
        // We set coordinates if we find them, or use notes/location string to default
        // Let's check address coordinates from dashboard addresses
        final matchingAddress = dashboardData?.addresses.firstWhere(
          (a) => a.formattedAddress == matching.location || a.addressLine1 == matching.location,
          orElse: () => const MapEntry('id', null) as dynamic,
        );
        final lat = matchingAddress?.latitude ?? 12.9716;
        final lng = matchingAddress?.longitude ?? 77.5946;
        setState(() {
          _destination = LatLng(lat, lng);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider(widget.bookingId));

    // Center map on technician location if available, otherwise destination
    final centerPoint = trackingState.technicianLocation ?? _destination;

    return Scaffold(
      backgroundColor: AppColors.slate950,
      appBar: AppBar(
        title: const Text('Live Technician Tracking'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Leaflet-style OSM Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPoint,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.techbes.customer_app',
              ),
              MarkerLayer(
                markers: [
                  // Destination Marker (Home/Office)
                  Marker(
                    point: _destination,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.emerald600.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.emerald600, width: 2),
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  // Live Technician Marker (Scooter / Avatar)
                  if (trackingState.technicianLocation != null)
                    Marker(
                      point: trackingState.technicianLocation!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.blue600.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.blue600, width: 2),
                        ),
                        child: const Icon(
                          Icons.motorcycle,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Info banner
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: AppColors.slate900.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.tealAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Status: ${trackingState.status.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      'ETA: ${trackingState.eta}',
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Technician Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.emerald600.withOpacity(0.2),
                        child: const Icon(Icons.person, color: Colors.tealAccent, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vikram Sharma',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Verified CCTV Technician Partner',
                              style: TextStyle(
                                color: AppColors.slate400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call, color: AppColors.emerald500),
                        onPressed: () {
                          // Simple visual trigger
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dialing Vikram Sharma: +91 98765 43210')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Colors.white10),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated Arrival',
                            style: TextStyle(color: AppColors.slate400, fontSize: 11),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Within 15 Mins',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Recenter map on technician
                          if (trackingState.technicianLocation != null) {
                            _mapController.move(trackingState.technicianLocation!, 15.5);
                          } else {
                            _mapController.move(_destination, 15.0);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.slate800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.my_location, size: 16),
                            SizedBox(width: 6),
                            Text('Recenter', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
