import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'models.dart';
import 'providers/live_technicians_provider.dart';

class FieldMapScreen extends ConsumerStatefulWidget {
  const FieldMapScreen({super.key});

  @override
  ConsumerState<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends ConsumerState<FieldMapScreen> {
  final Set<Marker> _markers = {};
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
    super.dispose();
  }

  void _applyTechnicians(List<Technician> techs) {
    if (mounted) {
      setState(() {
        _markers.clear();
        for (var t in techs) {
          if (t.isOnline && t.lat != null && t.lng != null) {
            _markers.add(
              Marker(
                markerId: MarkerId(t.id),
                position: LatLng(t.lat!, t.lng!),
                infoWindow: InfoWindow(title: t.name, snippet: t.status.name),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  t.status == TechnicianStatus.busy ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen
                ),
              ),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FLEET TRACKER"),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(liveTechniciansProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(13.0827, 80.2707), // Default to Chennai or user city
          zoom: 12,
        ),
        markers: _markers,
        onMapCreated: (c) {},
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
      ),
    );
  }
}
