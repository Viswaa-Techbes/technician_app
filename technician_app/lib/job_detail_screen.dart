import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'services/api_service.dart';
import 'models.dart';
import 'widgets.dart';
import 'features/job_description/widgets/job_description_section.dart';
import 'features/reviews/screens/submit_review_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'dart:math' as math;

class JobDetailScreen extends ConsumerStatefulWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  late JobStatus _currentStatus;
  late PaymentStatus _currentPaymentStatus;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;
  bool _isProcessingPayment = false;

  // OSM Map and Route state
  List<LatLng> _routePoints = [];
  double _distance = 0.0;
  double _eta = 0.0;
  LatLng? _technicianCoords;
  bool _loadingRoute = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.job.status;
    _currentPaymentStatus = widget.job.paymentStatus;
    if (_currentStatus == JobStatus.started) {
      _startTimer();
    }
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final bool coordsMissing = widget.job.latitude == null ||
        widget.job.longitude == null ||
        widget.job.latitude == 0.0 ||
        widget.job.longitude == 0.0;
    if (coordsMissing) {
      setState(() {
        _loadingRoute = false;
        _distance = 0.0;
        _eta = 0.0;
      });
      return;
    }

    final double custLat = widget.job.latitude!;
    final double custLng = widget.job.longitude!;
    
    setState(() => _loadingRoute = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _technicianCoords = LatLng(pos.latitude, pos.longitude);
      
      if (_technicianCoords != null) {
        final api = ref.read(apiServiceProvider);
        final baseUrl = api.baseUrl;
        final response = await http.get(
          Uri.parse('$baseUrl/api/v2/routing/directions?startLat=${_technicianCoords!.latitude}&startLng=${_technicianCoords!.longitude}&endLat=$custLat&endLng=$custLng'),
          headers: {
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['data'] != null) {
            final routeData = data['data'];
            final List coords = routeData['polyline'] ?? [];
            setState(() {
              _routePoints = coords.map((c) => LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble())).toList();
              _distance = (routeData['distanceKm'] as num).toDouble();
              _eta = (routeData['durationMinutes'] as num).toDouble();
            });
            
            // Adjust camera to fit bounds
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _routePoints.isNotEmpty) {
                final bounds = LatLngBounds.fromPoints(_routePoints);
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(50.0),
                  ),
                );
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[JobDetail] Routing error: $e');
      if (_technicianCoords != null) {
        final dist = _haversineDistance(
          _technicianCoords!.latitude,
          _technicianCoords!.longitude,
          custLat,
          custLng,
        );
        setState(() {
          _routePoints = [_technicianCoords!, LatLng(custLat, custLng)];
          _distance = dist;
          _eta = dist * 2;
        });
      }
    } finally {
      setState(() => _loadingRoute = false);
    }
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    final double dLat = (lat2 - lat1) * math.pi / 180;
    final double dLon = (lon2 - lon1) * math.pi / 180;
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 150),
                  child: Column(
                    children: [
                      _buildTimerSection(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),
                            _buildCustomerCard(),
                            _buildSectionHeader('Payment Summary'),
                            _buildPaymentCard(),
                            JobDescriptionSection(projectId: widget.job.id),
                            _buildSectionHeader('Project Site Location'),
                            _buildMapCard(),
                            _buildSectionHeader('Technical Documentation'),
                            _buildPhotoGrid(),
                            _buildSectionHeader('Project Attachments'),
                            _buildAttachmentsList(),
                            _buildSectionHeader('Field Observations'),
                            _buildNotesArea(),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomActionDock(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      title: Hero(
        tag: 'job-id-${widget.job.id}',
        child: Material(
          color: Colors.transparent,
          child: Text(
            'PROJECT #${widget.job.id}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF0F172A),
              fontSize: 14,
            ),
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildTimerSection() {
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Hero(
      tag: 'job-card-${widget.job.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 48),
          child: Column(
            children: [
              StatusChip(status: _currentStatus),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   _buildTimeSegment(hours, "HRS"),
                  _buildTimeSeparator(),
                  _buildTimeSegment(minutes, "MIN"),
                  _buildTimeSeparator(),
                  _buildTimeSegment(seconds, "SEC"),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _isRunning ? "TASK SESSION ACTIVE" : "SESSION PAUSED",
                style: TextStyle(
                  color: _isRunning ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSegment(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: _isRunning ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
            letterSpacing: -1,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade400,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 24),
      child: Text(
        ":",
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: Color(0xFF1E3A8A), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.job.customerName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const Text(
                      "Corporate Client",
                      style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F9FF),
                  foregroundColor: const Color(0xFF0369A1),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 40, 0, 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF94A3B8),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    final amountText = widget.job.price.toStringAsFixed(2);
    final isPaid = _currentPaymentStatus == PaymentStatus.paid;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amount to Collect',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
              ),
              Text(
                'INR $amountText',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1E3A8A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPaymentInfoChip(
                  isPaid ? 'PAID' : 'PENDING',
                  isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.job.orderId?.isNotEmpty == true ? 'Order: ${widget.job.orderId}' : 'Order not linked',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Future<void> _openGoogleMapsNavigation() async {
    Uri url;
    final double lat = widget.job.latitude ?? 13.0827;
    final double lng = widget.job.longitude ?? 80.2707;
    if (Platform.isIOS) {
      url = Uri.parse('https://maps.apple.com/?saddr=&daddr=$lat,$lng');
    } else {
      url = Uri.parse('google.navigation:q=$lat,$lng');
      if (!await canLaunchUrl(url)) {
        url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      }
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map navigation application')),
        );
      }
    }
  }

  Future<void> _callCustomer() async {
    final phone = widget.job.customerPhone;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No customer phone number available'), backgroundColor: Colors.red),
      );
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not initiate call to $phone'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelJob() async {
    final reasons = [
      'Vehicle Breakdown',
      'Personal Emergency',
      'Client Unavailable / Not reachable',
      'Incorrect location / Too far',
      'Equipment issues',
      'Other'
    ];
    String selectedReason = reasons.first;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Cancel Job?', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you sure you want to cancel this job? A penalty of ₹50 will be applied to your account.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Reason:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedReason,
                        items: reasons.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedReason = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('No, Keep Job', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        final api = ref.read(apiServiceProvider);
        await api.techCancelJob(widget.job.id, selectedReason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job cancelled. Penalty has been applied.'), backgroundColor: Colors.red),
          );
          Navigator.pop(context); // Close the detail screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel job: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildMapCard() {
    final bool coordsMissing = widget.job.latitude == null ||
        widget.job.longitude == null ||
        widget.job.latitude == 0.0 ||
        widget.job.longitude == 0.0;

    if (coordsMissing) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 40),
            SizedBox(height: 12),
            Text(
              'Customer location coordinates missing.\nPlease contact customer or dispatch manager.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF991B1B),
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final double lat = widget.job.latitude!;
    final double lng = widget.job.longitude!;
    final LatLng customerPos = LatLng(lat, lng);

    final List<Marker> markers = [
      Marker(
        point: customerPos,
        width: 45,
        height: 45,
        child: const Icon(
          Icons.pin_drop_rounded,
          color: Colors.red,
          size: 38,
        ),
      ),
    ];

    if (_technicianCoords != null) {
      markers.add(
        Marker(
          point: _technicianCoords!,
          width: 45,
          height: 45,
          child: const Icon(
            Icons.directions_run_rounded,
            color: Colors.green,
            size: 38,
          ),
        ),
      );
    }

    return Container(
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: customerPos,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.technicianapp.app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF2563EB),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: markers,
              ),
            ],
          ),
          
          if (_technicianCoords != null && !_loadingRoute)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.navigation_rounded, size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'DISTANCE',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            Text(
                              '${_distance.toStringAsFixed(1)} km',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, size: 18, color: Color(0xFF22C55E)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'ETA',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            Text(
                              '${_eta.toStringAsFixed(0)} mins',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (_loadingRoute)
            Container(
              color: Colors.white.withValues(alpha: 0.6),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pin_drop_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    widget.job.address.length > 24
                        ? '${widget.job.address.substring(0, 24)}…'
                        : widget.job.address,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _openGoogleMapsNavigation,
              backgroundColor: const Color(0xFF2563EB),
              child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Row(
      children: [
        Expanded(child: _buildPhotoBox("SITE BEFORE", Icons.history_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _buildPhotoBox("SITE AFTER", Icons.verified_rounded)),
      ],
    );
  }

  Widget _buildPhotoBox(String label, IconData icon) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 24),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList() {
    final files = widget.job.fileAttachments ?? [];
    if (files.isEmpty) {
      return const Text("No attachments provided", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13));
    }
    return Column(
      children: files.map((path) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_rounded, color: Color(0xFF3B82F6), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                path.split('/').last,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.file_download_outlined, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildNotesArea() {
    return TextField(
      maxLines: 4,
      decoration: InputDecoration(
        hintText: "Enter detailed site observations...",
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: const Color(0xFFF1F5F9))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: const Color(0xFFF1F5F9))),
        contentPadding: const EdgeInsets.all(24),
      ),
    );
  }

  Widget _buildBottomActionDock() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 30, offset: const Offset(0, -10)),
          ],
        ),
        child: _buildActionButtonForStatus(),
      ),
    );
  }

  Future<void> _updateStatus(String newStatus, {List<String>? attachments}) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.updateJobStatus(widget.job.id, newStatus, attachments: attachments);
    } catch (e) {
      debugPrint("Failed to update status: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _uploadWork() async {
    final source = await showModalBottomSheet<_WorkProofSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload work proof',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a fresh site photo or choose images from your gallery.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              _buildWorkProofSourceTile(
                icon: Icons.photo_camera_rounded,
                title: 'Open camera',
                subtitle: 'Capture one photo now',
                onTap: () => Navigator.pop(context, _WorkProofSource.camera),
              ),
              const SizedBox(height: 12),
              _buildWorkProofSourceTile(
                icon: Icons.photo_library_rounded,
                title: 'Choose from gallery',
                subtitle: 'Upload one or more images',
                onTap: () => Navigator.pop(context, _WorkProofSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final List<Map<String, dynamic>> filesData = [];

      if (source == _WorkProofSource.camera) {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1600,
        );

        if (image == null) return;

        filesData.add({
          'bytes': await image.readAsBytes(),
          'name': image.name.isNotEmpty ? image.name : 'camera-${DateTime.now().millisecondsSinceEpoch}.jpg',
        });
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.image,
          withData: true, // Required for web/certain platforms
        );

        if (result == null || result.files.isEmpty) return;

        for (var file in result.files) {
          List<int>? bytes = file.bytes;
          if (bytes == null && file.path != null) {
            bytes = await File(file.path!).readAsBytes();
          }
          if (bytes != null) {
            filesData.add({'bytes': bytes, 'name': file.name});
          }
        }
      }

      if (filesData.isNotEmpty) {
        setState(() => _isProcessingPayment = true);

        final api = ref.read(apiServiceProvider);
        final downloadUrls = await api.uploadFiles(filesData);
        if (downloadUrls.isNotEmpty) {
          await _updateStatus('work_uploaded', attachments: downloadUrls);
          setState(() => _currentStatus = JobStatus.workUploaded);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Work proof uploaded to Cloudinary successfully.")),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  Widget _buildWorkProofSourceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
              child: Icon(icon, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Future<String?> _showOtpDialog(String purpose, String? devOtp) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(purpose == 'start' ? 'Verify Job Start' : 'Verify Job Completion', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('An OTP has been sent to the customer. Please enter it below to confirm:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Enter 6-digit OTP',
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4),
                textAlign: TextAlign.center,
              ),
              if (devOtp != null) ...[
                const SizedBox(height: 12),
                Text('(Dev Mode: OTP is $devOtp)', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('VERIFY', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentQR() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Scan PhonePe QR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AMOUNT: INR ${widget.job.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Image.asset(
                'assets/payments/techbes_phonepe_qr.png',
                width: 240,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 240,
                  height: 320,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'PhonePe QR image missing.\nAdd it at assets/payments/techbes_phonepe_qr.png',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Ask the customer to scan and pay to TECHBES.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _updateStatus('payment_done');
                      if (!mounted) return;
                      Navigator.pop(context);
                      setState(() {
                        _currentStatus = JobStatus.completed;
                        _currentPaymentStatus = PaymentStatus.paid;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment marked as collected.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('PAID', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonForStatus() {
    switch (_currentStatus) {
      case JobStatus.assigned:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: "NAVIGATE",
                    onPressed: _openGoogleMapsNavigation,
                    color: const Color(0xFF3B82F6),
                    icon: Icons.directions_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: "CALL",
                    onPressed: _callCustomer,
                    color: const Color(0xFF10B981),
                    icon: Icons.call,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: "CANCEL",
                    onPressed: _cancelJob,
                    color: const Color(0xFFEF4444),
                    icon: Icons.cancel_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: "START JOB",
              onPressed: () async {
                try {
                  final api = ref.read(apiServiceProvider);
                  final res = await api.requestStartOtp(widget.job.id);
                  final devOtp = res['otp'] as String?;
                  final otpInput = await _showOtpDialog('start', devOtp);
                  if (otpInput != null && otpInput.isNotEmpty) {
                    await api.verifyStartOtp(widget.job.id, otpInput);
                    setState(() => _currentStatus = JobStatus.started);
                    _startTimer();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🎉 Job started successfully!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to start job: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              color: const Color(0xFF2563EB),
              icon: Icons.play_circle_rounded,
            ),
          ],
        );
      case JobStatus.started:
        return Row(
          children: [
            Expanded(
              child: _isRunning
                  ? CustomButton(label: "PAUSE", onPressed: _pauseTimer, color: const Color(0xFFF59E0B), icon: Icons.pause_circle_rounded)
                  : CustomButton(label: "START", onPressed: _startTimer, color: const Color(0xFF2563EB), icon: Icons.play_circle_rounded),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                label: "SITE VISIT DONE",
                onPressed: _uploadWork,
                color: const Color(0xFF8B5CF6),
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        );
      case JobStatus.workUploaded:
        return CustomButton(
          label: "COMPLETE JOB (OTP)",
          onPressed: () async {
            try {
              final api = ref.read(apiServiceProvider);
              final res = await api.requestCompleteOtp(widget.job.id);
              final devOtp = res['otp'] as String?;
              final otpInput = await _showOtpDialog('complete', devOtp);
              if (otpInput != null && otpInput.isNotEmpty) {
                await api.verifyCompleteOtp(widget.job.id, otpInput);
                setState(() => _currentStatus = JobStatus.completed);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎉 Job completed successfully!'), backgroundColor: Colors.green),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to complete job: $e'), backgroundColor: Colors.red),
              );
            }
          },
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_rounded,
        );
      case JobStatus.completionRequested:
        return CustomButton(
          label: "WAITING FOR APPROVAL",
          onPressed: () {},
          color: const Color(0xFF64748B),
          icon: Icons.hourglass_bottom_rounded,
        );
      case JobStatus.approvedByManager:
      case JobStatus.paymentRequested:
      case JobStatus.paymentPending:
        if (_currentPaymentStatus != PaymentStatus.paid) {
          return CustomButton(
            label: _isProcessingPayment ? "PROCESSING PAYMENT" : "COLLECT PAYMENT",
            onPressed: _isProcessingPayment ? () {} : _showPaymentQR,
            color: const Color(0xFF10B981),
            icon: Icons.qr_code_scanner_rounded,
          );
        }
        return const SizedBox();
      case JobStatus.paymentDone:
      case JobStatus.completed:
        return CustomButton(
          label: "COLLECT CLIENT REVIEW",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubmitReviewScreen(
                  technicianId: widget.job.technicianId ?? '',
                  technicianName: widget.job.technicianName ?? "Technician",
                  projectId: widget.job.id,
                  clientName: widget.job.customerName,
                ),
              ),
            );
          },
          color: const Color(0xFFF59E0B),
          icon: Icons.star_rounded,
        );
    }
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    // Horizontal lines
    const spacing = 28.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Cross-hair center lines
    final cx = size.width / 2;
    final cy = size.height / 2 - 20;
    final crossPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.12)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), crossPaint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _WorkProofSource { camera, gallery }
