import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_config.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const LiveTrackingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  io.Socket? _socket;
  final MapController _mapController = MapController();

  // Booking & Tech Details
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _booking;
  String? _assignedTechId;
  String _techName = 'Technician';
  String _techPhone = '';
  String _techPhoto = '';

  // Coordinates
  LatLng? _customerLatLng;
  LatLng? _techLatLng;

  // Tracking Stats
  double _distanceKm = 0;
  int _etaMinutes = 0;
  bool _isLiveConnected = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/user/dashboard');
      
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data']['bookings'] as List<dynamic>? ?? [];
        final found = list.firstWhere(
          (b) => b['_id'] == widget.bookingId,
          orElse: () => null,
        );

        if (found != null) {
          final assigned = found['assignedTechnician'];
          double? custLat = double.tryParse(found['latitude']?.toString() ?? '');
          double? custLng = double.tryParse(found['longitude']?.toString() ?? '');
          
          setState(() {
            _booking = found;
            _customerLatLng = custLat != null && custLng != null ? LatLng(custLat, custLng) : null;
            
            if (assigned != null) {
              _assignedTechId = assigned['_id'] ?? assigned['id'];
              _techName = assigned['name'] ?? 'Technician';
              _techPhone = assigned['mobileNumber'] ?? assigned['phone'] ?? '9999999999';
              _techPhoto = assigned['profilePhoto'] ?? '';
              
              // Load technician's last known location from booking object if present
              double? techLat = double.tryParse(assigned['lat']?.toString() ?? '');
              double? techLng = double.tryParse(assigned['lng']?.toString() ?? '');
              if (techLat != null && techLng != null) {
                _techLatLng = LatLng(techLat, techLng);
              }
            }
            _isLoading = false;
          });

          // Connect live socket
          _connectSocket();
          _recalculateStats();
        } else {
          setState(() {
            _errorMessage = 'Booking not found in dashboard archives.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching tracking info: $e');
      setState(() {
        _errorMessage = 'Failed to load booking details.';
        _isLoading = false;
      });
    }
  }

  void _connectSocket() {
    if (_assignedTechId == null) return;

    debugPrint('[Tracking] Connecting to Socket.IO live tracking...');
    _socket = io.io(ApiConfig.baseUrl, io.OptionBuilder()
        .setTransports(['websocket'])
        .setQuery({'bookingId': widget.bookingId})
        .build());

    _socket?.onConnect((_) {
      debugPrint('[Tracking] Socket connected successfully');
      setState(() {
        _isLiveConnected = true;
      });
      // Join the admin room to capture technicianLocationUpdate broadcasts
      _socket?.emit('join_admin');
    });

    _socket?.on('technicianLocationUpdate', (data) {
      debugPrint('[Tracking] Location update broadcast received: $data');
      if (data is Map) {
        final tId = data['technicianId'] ?? data['userId'];
        if (tId == _assignedTechId) {
          final latVal = double.tryParse(data['lat']?.toString() ?? '');
          final lngVal = double.tryParse(data['lng']?.toString() ?? '');
          
          if (latVal != null && lngVal != null) {
            setState(() {
              _techLatLng = LatLng(latVal, lngVal);
            });
            _recalculateStats();
            _animateMapToFit();
          }
        }
      }
    });

    _socket?.onDisconnect((_) {
      debugPrint('[Tracking] Socket disconnected');
      setState(() {
        _isLiveConnected = false;
      });
    });

    _socket?.connect();
  }

  void _recalculateStats() {
    if (_customerLatLng == null || _techLatLng == null) return;

    // Calculate spherical distance
    const Distance distance = Distance();
    final double distMeter = distance.as(LengthUnit.Meter, _techLatLng!, _customerLatLng!);
    
    // Assume average speed 25 km/h (approx 6.94 m/s)
    const double speedMps = 25 * 1000 / 3600; 
    final int minutes = (distMeter / speedMps / 60).round();

    setState(() {
      _distanceKm = distMeter / 1000;
      _etaMinutes = max(2, minutes); // minimum 2 min ETA
    });
  }

  void _animateMapToFit() {
    if (_customerLatLng == null || _techLatLng == null) return;
    
    // Bounds calculations
    final bounds = LatLngBounds(_customerLatLng!, _techLatLng!);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Tracking')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final initialCenter = _techLatLng ?? _customerLatLng ?? const LatLng(12.9716, 77.5946);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Technician'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isLiveConnected ? const Color(0xFF10B981) : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isLiveConnected ? 'Live' : 'Offline',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isLiveConnected ? const Color(0xFF10B981) : Colors.red),
                ),
              ],
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Leaflet OSM Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.5,
              onMapReady: () {
                // Center bounds to show both pins after loaded
                Future.delayed(const Duration(milliseconds: 600), () {
                  _animateMapToFit();
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: [
                  // Customer Marker Pin
                  if (_customerLatLng != null)
                    Marker(
                      point: _customerLatLng!,
                      width: 48,
                      height: 48,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: const CircleAvatar(
                          backgroundColor: Color(0xFF10B981),
                          child: Icon(Icons.home, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  
                  // Technician Marker Pin
                  if (_techLatLng != null)
                    Marker(
                      point: _techLatLng!,
                      width: 52,
                      height: 52,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.motorcycle, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Bottom Technician Panel Overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.12),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stats header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.directions_bike, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _techLatLng == null 
                                    ? 'Technician on the way' 
                                    : 'Arriving in $_etaMinutes mins',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimaryColor),
                              ),
                              Text(
                                _techLatLng == null 
                                    ? 'Awaiting technician GPS signal' 
                                    : '${_distanceKm.toStringAsFixed(1)} km away from your location',
                                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Technician details
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.blueGrey.shade50,
                          backgroundImage: _techPhoto.isNotEmpty ? NetworkImage(_techPhoto) : null,
                          child: _techPhoto.isEmpty ? const Icon(Icons.person, color: AppTheme.textSecondaryColor) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _techName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor),
                              ),
                              const Text(
                                'Certified Service Partner',
                                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (_techPhone.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.call, color: AppTheme.primaryColor),
                            onPressed: () async {
                              final url = Uri.parse('tel:$_techPhone');
                              if (await canLaunchUrl(url)) await launchUrl(url);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
