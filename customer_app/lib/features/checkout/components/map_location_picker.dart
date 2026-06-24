import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';

class MapLatLng {
  final double latitude;
  final double longitude;
  const MapLatLng(this.latitude, this.longitude);
}

class MapLocationResult {
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;

  MapLocationResult({
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
  });
}

class MapLocationPicker extends StatefulWidget {
  final MapLatLng? initialCoords;
  final Function(MapLocationResult) onLocationSelected;

  const MapLocationPicker({
    super.key,
    this.initialCoords,
    required this.onLocationSelected,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final _searchController = TextEditingController();
  final MapController _mapController = MapController();
  
  LatLng _markerPosition = const LatLng(12.9716, 77.5946); // Default: Bangalore
  
  bool _isSearching = false;
  bool _isGeocoding = false;
  bool _showSuggestions = false;
  
  List<dynamic> _suggestions = [];
  Timer? _debounceTimer;
  final Dio _dio = Dio();

  // Resolved address info
  String _address = '';
  String _city = '';
  String _state = '';
  String _pincode = '';

  @override
  void initState() {
    super.initState();
    _dio.options.headers['User-Agent'] = 'TechnicianApp/1.0';

    if (widget.initialCoords != null) {
      _markerPosition = LatLng(widget.initialCoords!.latitude, widget.initialCoords!.longitude);
      _reverseGeocode(_markerPosition);
    } else {
      _reverseGeocode(_markerPosition);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() {
      _isGeocoding = true;
    });

    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1';
      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final addressDetails = data['address'] ?? {};
        
        setState(() {
          _address = data['display_name'] ?? '';
          _city = addressDetails['city'] ?? addressDetails['town'] ?? addressDetails['village'] ?? addressDetails['county'] ?? '';
          _state = addressDetails['state'] ?? '';
          _pincode = addressDetails['postcode'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    } finally {
      setState(() {
        _isGeocoding = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      setState(() {
        _isSearching = true;
      });

      try {
        final url = 'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&countrycodes=in&limit=5&addressdetails=1';
        final response = await _dio.get(url);
        
        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            _suggestions = response.data;
            _showSuggestions = _suggestions.isNotEmpty;
          });
        }
      } catch (e) {
        debugPrint('Geocode search error: $e');
      } finally {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _selectSuggestion(dynamic suggestion) {
    final lat = double.parse(suggestion['lat'].toString());
    final lon = double.parse(suggestion['lon'].toString());
    final newPos = LatLng(lat, lon);

    setState(() {
      _markerPosition = newPos;
      _showSuggestions = false;
      _searchController.text = suggestion['display_name'] ?? '';
      
      _address = suggestion['display_name'] ?? '';
      final addressDetails = suggestion['address'] ?? {};
      _city = addressDetails['city'] ?? addressDetails['town'] ?? addressDetails['village'] ?? addressDetails['county'] ?? '';
      _state = addressDetails['state'] ?? '';
      _pincode = addressDetails['postcode'] ?? '';
    });

    _mapController.move(newPos, 16);
  }

  void _confirmSelection() {
    widget.onLocationSelected(
      MapLocationResult(
        address: _address,
        city: _city,
        state: _state,
        pincode: _pincode,
        latitude: _markerPosition.latitude,
        longitude: _markerPosition.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search address, landmark...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),

        // Suggestions Dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, color: AppTheme.textSecondaryColor, size: 18),
                  title: Text(
                    item['display_name'] ?? '',
                    style: const TextStyle(fontSize: 12.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectSuggestion(item),
                );
              },
            ),
          ),

        const SizedBox(height: 14),

        // Map View
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _markerPosition,
                  initialZoom: 16.0,
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      setState(() {
                        _markerPosition = position.center;
                      });
                    }
                  },
                  onMapEvent: (event) {
                    // Trigger reverse geocoding once map manipulation ends
                    if (event is MapEventMoveEnd) {
                      _reverseGeocode(_markerPosition);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                  ),
                ],
              ),
              // Centred Marker pin mimicking map drag coordinates
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Icon(
                    Icons.location_on,
                    size: 40,
                    color: _isGeocoding ? AppTheme.textSecondaryColor : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Confirm geocoded address card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SERVICE LOCATION DETAIL',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor, letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              if (_isGeocoding)
                const Row(
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
                    SizedBox(width: 8),
                    Text('Resolving map pin...', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor)),
                  ],
                )
              else
                Text(
                  _address.isNotEmpty ? _address : 'Drag the map to position the service address pin.',
                  style: TextStyle(fontSize: 12.5, color: _address.isNotEmpty ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor, height: 1.4),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        ElevatedButton.icon(
          onPressed: _isGeocoding || _address.isEmpty ? null : _confirmSelection,
          icon: const Icon(Icons.check, size: 20),
          label: const Text('Confirm Map Location'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}
