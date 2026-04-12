import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/api_service.dart';
import 'models.dart';

class FieldMapScreen extends ConsumerStatefulWidget {
  const FieldMapScreen({super.key});

  @override
  ConsumerState<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends ConsumerState<FieldMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchAndMarkTechnicians();
  }

  Future<void> _fetchAndMarkTechnicians() async {
    final api = ref.read(apiServiceProvider);
    final techs = await api.getTechnicians();
    
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
          IconButton(onPressed: _fetchAndMarkTechnicians, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(13.0827, 80.2707), // Default to Chennai or user city
          zoom: 12,
        ),
        markers: _markers,
        onMapCreated: (c) => _mapController = c,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
      ),
    );
  }
}
