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
  GoogleMapController? _mapController;
  ProviderSubscription<AsyncValue<List<Technician>>>? _techniciansSubscription;

  final String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#746855"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#263c3f"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6b9a76"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#38414e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a37"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#1f2835"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#f3d19c"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#515c6d"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#17263c"}]
  }
]
''';

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
    _mapController?.dispose();
    super.dispose();
  }

  void _applyTechnicians(List<Technician> techs) {
    if (!mounted) return;
    
    setState(() {
      _markers.clear();
      for (var t in techs) {
        // Show everyone with valid coordinates (even if offline)
        if (t.lat != null && t.lng != null && t.lat != 0 && t.lng != 0) {
          double hue = BitmapDescriptor.hueAzure; // Offline/Default
          if (t.isOnline) {
             hue = t.status == TechnicianStatus.busy 
                ? BitmapDescriptor.hueOrange 
                : BitmapDescriptor.hueGreen;
          }

          _markers.add(
            Marker(
              markerId: MarkerId(t.id),
              position: LatLng(t.lat!, t.lng!),
              infoWindow: InfoWindow(
                title: t.name, 
                snippet: "${t.isOnline ? 'Online' : 'Offline'} • ${t.status.name.toUpperCase()}"
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            ),
          );
        }
      }
    });

    _fitMarkers();
  }

  void _fitMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (var marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // Padding
      ),
    );
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
          target: LatLng(20.5937, 78.9629), // Center of India
          zoom: 5,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
          _mapController?.setMapStyle(_mapStyle);
          _fitMarkers();
        },
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }
}
