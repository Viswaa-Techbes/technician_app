import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import 'models.dart';
import 'providers/live_technicians_provider.dart';

class FieldMapScreen extends ConsumerStatefulWidget {
  const FieldMapScreen({super.key});

  @override
  ConsumerState<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends ConsumerState<FieldMapScreen> {
  final MapController _mapController = MapController();
  List<Technician> _techs = [];
  ProviderSubscription<AsyncValue<List<Technician>>>? _techniciansSubscription;

  @override
  void initState() {
    super.initState();
    _techniciansSubscription = ref.listenManual(liveTechniciansProvider, (previous, next) {
      next.whenData(_applyTechnicians);
    });
    Future.microtask(() {
      final technicians = ref.read(liveTechniciansProvider).valueOrNull;
      if (technicians != null) {
        _applyTechnicians(technicians);
      }
    });
  }

  @override
  void dispose() {
    _techniciansSubscription?.close();
    _mapController.dispose();
    super.dispose();
  }

  void _applyTechnicians(List<Technician> techs) {
    if (!mounted) return;
    setState(() {
      _techs = techs;
    });
    _fitMarkers();
  }

  void _fitMarkers() {
    final activePoints = _techs
        .where((t) => t.lat != null && t.lng != null && t.lat != 0 && t.lng != 0)
        .map((t) => LatLng(t.lat!, t.lng!))
        .toList();

    if (activePoints.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final bounds = LatLngBounds.fromPoints(activePoints);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50.0),
          ),
        );
      } catch (e) {
        debugPrint('[FieldMap] Failed to fit bounds: $e');
      }
    });
  }

  Color _getStatusColor(Technician t) {
    if (!t.isOnline) return const Color(0xFF64748B); // Offline grey
    return t.status == TechnicianStatus.busy
        ? const Color(0xFFF97316) // Busy orange
        : const Color(0xFF22C55E); // Available green
  }

  List<Marker> _buildMarkers() {
    return _techs
        .where((t) => t.lat != null && t.lng != null && t.lat != 0 && t.lng != 0)
        .map((t) {
      final statusColor = _getStatusColor(t);
      return Marker(
        point: LatLng(t.lat!, t.lng!),
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Role: ${t.specialty}'),
                    const SizedBox(height: 4),
                    Text('Phone: ${t.phone}'),
                    const SizedBox(height: 4),
                    Text('Status: ${t.isOnline ? 'Online' : 'Offline'} • ${t.status.name.toUpperCase()}'),
                    const SizedBox(height: 4),
                    Text('Completed Jobs: ${t.completedJobs}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.3),
                ),
              ),
              // Inner border and dot
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FLEET TRACKER"),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(liveTechniciansProvider);
              _fitMarkers();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(20.5937, 78.9629), // Center of India
          initialZoom: 5,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.technicianapp.app',
          ),
          MarkerLayer(
            markers: _buildMarkers(),
          ),
        ],
      ),
    );
  }
}
