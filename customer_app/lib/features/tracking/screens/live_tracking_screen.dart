import 'dart:async';
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
  String _techName = 'Technician Partner';
  String _techPhone = '';
  String _techPhoto = '';
  double _techRating = 4.9;
  String? _startJobOtp;

  // Coordinates
  LatLng? _customerLatLng;
  LatLng? _techLatLng;

  // Tracking Stats
  double _distanceKm = 0;
  int _etaMinutes = 0;
  bool _isLiveConnected = false;
  String _currentStatus = 'confirmed';

  // Milestone Progress
  final List<String> _milestones = [
    'Booking Confirmed',
    'Technician Assigned',
    'Technician Accepted',
    'Travelling',
    'Live Location',
    'Arrived',
    'Work Started',
    'Work Completed',
    'Invoice Generated',
    'Review Submitted',
  ];

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
            _currentStatus = (found['status'] ?? found['bookingStatus'] ?? 'confirmed').toString().toLowerCase();
            _startJobOtp = found['startJobOtp']?.toString();
            _customerLatLng = custLat != null && custLng != null ? LatLng(custLat, custLng) : LatLng(12.9716, 77.5946);
            
            if (assigned != null) {
              _assignedTechId = assigned['_id'] ?? assigned['id'];
              _techName = assigned['name'] ?? 'Technician';
              _techPhone = assigned['mobileNumber'] ?? assigned['phone'] ?? '9999999999';
              _techPhoto = assigned['profilePhoto'] ?? '';
              _techRating = (assigned['rating'] ?? 4.9).toDouble();
              
              double? techLat = double.tryParse(assigned['lat']?.toString() ?? '');
              double? techLng = double.tryParse(assigned['lng']?.toString() ?? '');
              if (techLat != null && techLng != null) {
                _techLatLng = LatLng(techLat, techLng);
              } else {
                // Mock starting position slightly away from customer
                _techLatLng = LatLng(_customerLatLng!.latitude + 0.015, _customerLatLng!.longitude + 0.015);
              }
            } else {
              // Mock tech for preview if unassigned
              _techName = 'Arun Kumar';
              _techPhone = '9876543210';
              _techLatLng = LatLng(_customerLatLng!.latitude + 0.015, _customerLatLng!.longitude + 0.015);
            }
            _isLoading = false;
          });

          _connectSocket();
          _recalculateStats();
          _animateMapToFit();
        } else {
          setState(() {
            _errorMessage = 'Booking details not found.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading tracking: $e');
      setState(() {
        _errorMessage = 'Failed to retrieve tracking data.';
        _isLoading = false;
      });
    }
  }

  void _connectSocket() {
    debugPrint('[Socket] Connecting to live socket endpoint...');
    _socket = io.io(ApiConfig.baseUrl, io.OptionBuilder()
        .setTransports(['websocket'])
        .setQuery({'bookingId': widget.bookingId})
        .build());

    _socket?.onConnect((_) {
      setState(() => _isLiveConnected = true);
      _socket?.emit('join_admin');
    });

    _socket?.on('technicianLocationUpdate', (data) {
      debugPrint('[Socket] Received live coordinate update: $data');
      if (data is Map) {
        final tId = data['technicianId'] ?? data['userId'];
        if (tId == _assignedTechId || _assignedTechId == null) {
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

    _socket?.on('bookingStatusUpdate', (data) {
      debugPrint('[Socket] Received live status update: $data');
      if (data is Map && data['bookingId'] == widget.bookingId) {
        setState(() {
          _currentStatus = (data['status'] ?? _currentStatus).toString().toLowerCase();
        });
      }
    });

    _socket?.onDisconnect((_) {
      setState(() => _isLiveConnected = false);
    });

    _socket?.connect();
  }

  void _recalculateStats() {
    if (_customerLatLng == null || _techLatLng == null) return;
    const distanceCalculator = Distance();
    final double dist = distanceCalculator.as(LengthUnit.Meter, _techLatLng!, _customerLatLng!);
    
    // speed approx 25km/h
    final int eta = (dist / (25 * 1000 / 3600) / 60).round();
    setState(() {
      _distanceKm = dist / 1000;
      _etaMinutes = max(1, eta);
    });
  }

  void _animateMapToFit() {
    if (_customerLatLng == null || _techLatLng == null) return;
    final bounds = LatLngBounds(_customerLatLng!, _techLatLng!);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)));
  }

  int _getCurrentMilestoneIndex() {
    switch (_currentStatus.toLowerCase()) {
      case 'pending':
      case 'confirmed':
        return 0;
      case 'assigned':
        return 1;
      case 'accepted':
        return 2;
      case 'travelling':
        return 3;
      case 'live':
      case 'location_shared':
        return 4;
      case 'arrived':
        return 5;
      case 'working':
      case 'in_progress':
      case 'started':
        return 6;
      case 'completed':
        return 7;
      case 'invoice_generated':
      case 'payment_done':
        return 8;
      case 'reviewed':
      case 'submitted':
        return 9;
      default:
        return 0;
    }
  }

  // Simulator helper to demonstrate live progress
  void _simulateProgressStep() {
    final currentIdx = _getCurrentMilestoneIndex();
    if (currentIdx < _milestones.length - 1) {
      final nextIdx = currentIdx + 1;
      String nextStatus = 'confirmed';
      if (nextIdx == 1) nextStatus = 'assigned';
      if (nextIdx == 2) nextStatus = 'accepted';
      if (nextIdx == 3) nextStatus = 'travelling';
      if (nextIdx == 4) nextStatus = 'live';
      if (nextIdx == 5) nextStatus = 'arrived';
      if (nextIdx == 6) nextStatus = 'working';
      if (nextIdx == 7) nextStatus = 'completed';
      if (nextIdx == 8) nextStatus = 'invoice_generated';
      if (nextIdx == 9) nextStatus = 'reviewed';

      // Simulate coordinate moving closer to customer
      if (_techLatLng != null && _customerLatLng != null) {
        final double factor = (9 - nextIdx) / 9; // move closer
        final lat = _customerLatLng!.latitude + (_techLatLng!.latitude - _customerLatLng!.latitude) * factor;
        final lng = _customerLatLng!.longitude + (_techLatLng!.longitude - _customerLatLng!.longitude) * factor;
        setState(() {
          _techLatLng = LatLng(lat, lng);
        });
      }

      setState(() {
        _currentStatus = nextStatus;
      });
      _recalculateStats();
      _animateMapToFit();
      
      // Emit mock update
      _socket?.emit('simulate_status', {'bookingId': widget.bookingId, 'status': nextStatus});
    }
  }

  void _openWhatsApp() async {
    final url = Uri.parse('whatsapp://send?phone=91$_techPhone&text=Hello%20TechBes%20Partner,%20I%20am%20tracking%20your%20arrival.');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Fallback to web link
      final webUrl = Uri.parse('https://wa.me/91$_techPhone');
      if (await canLaunchUrl(webUrl)) await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final center = _techLatLng ?? _customerLatLng ?? const LatLng(12.9716, 77.5946);
    final activeIdx = _getCurrentMilestoneIndex();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookingDetails,
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: AppTheme.secondaryColor),
            tooltip: 'Simulate Step',
            onPressed: _simulateProgressStep,
          ),
        ],
      ),
      body: Stack(
        children: [
          // FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14.5,
              onMapReady: () {
                Future.delayed(const Duration(milliseconds: 500), _animateMapToFit);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: [
                  if (_customerLatLng != null)
                    Marker(
                      point: _customerLatLng!,
                      width: 45,
                      height: 45,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                        child: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.home, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  if (_techLatLng != null)
                    Marker(
                      point: _techLatLng!,
                      width: 50,
                      height: 50,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)]),
                        child: const CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(Icons.motorcycle, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Sliding milestone progression bottom sheet overlay
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.22,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, -5)),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Pull bar
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.blueGrey.shade100, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 16),

                    // ETA & Distance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeIdx >= 7 ? 'Service Completed 🎉' : 'Arriving in $_etaMinutes mins',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimaryColor),
                            ),
                            Text(
                              activeIdx >= 7 ? 'Thank you for choosing TechBes' : '${_distanceKm.toStringAsFixed(1)} km away • GPS Live',
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (_startJobOtp != null && activeIdx < 6)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              children: [
                                const Text('START OTP', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
                                Text(_startJobOtp!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Tech Partner details
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blueGrey.shade50,
                          backgroundImage: _techPhoto.isNotEmpty ? NetworkImage(_techPhoto) : null,
                          child: _techPhoto.isEmpty ? const Icon(Icons.person, size: 24, color: AppTheme.textSecondaryColor) : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_techName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor)),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 13, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text('$_techRating Rating • TechBes Verified', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.message, color: Colors.green),
                          onPressed: _openWhatsApp,
                        ),
                        IconButton(
                          icon: const Icon(Icons.call, color: AppTheme.primaryColor),
                          onPressed: () async {
                            final uri = Uri.parse('tel:$_techPhone');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 28),

                    // Timeline Milestones Stepper (Shown when pulled up)
                    const Text('SERVICE BOOKING TIMELINE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.textSecondaryColor, letterSpacing: 0.5)),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _milestones.length,
                      itemBuilder: (context, idx) {
                        final done = idx <= activeIdx;
                        final current = idx == activeIdx;
                        
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stepper Line & circle
                            Column(
                              children: [
                                CircleAvatar(
                                  radius: current ? 9 : 7,
                                  backgroundColor: done ? AppTheme.primaryColor : Colors.blueGrey.shade100,
                                  child: current
                                      ? const CircleAvatar(radius: 4, backgroundColor: Colors.white)
                                      : done
                                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                                          : null,
                                ),
                                if (idx != _milestones.length - 1)
                                  Container(
                                    width: 2.5,
                                    height: 30,
                                    color: idx < activeIdx ? AppTheme.primaryColor : Colors.blueGrey.shade100,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            // Milestone text
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  _milestones[idx],
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: done ? FontWeight.bold : FontWeight.w500,
                                    color: current
                                        ? AppTheme.primaryColor
                                        : done
                                            ? AppTheme.textPrimaryColor
                                            : AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
