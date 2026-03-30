import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'core/network/api_config.dart';

class LocationService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/location';
  static final LocationService _instance = LocationService._internal();
  Timer? _timer;
  String? _currentTechnicianId;
  bool _isTracking = false;

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  bool get isTracking => _isTracking;

  /// Starts tracking location for the given technician and sends updates every 15 seconds
  Future<void> startTracking(String technicianId) async {
    if (_isTracking) return;
    
    _currentTechnicianId = technicianId;
    
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    _isTracking = true;

    // Send the first update immediately
    _sendLocationUpdate();

    // Set up periodic timer for 15 seconds
    _timer = Timer.periodic(const Duration(seconds: 15), (Timer t) {
      _sendLocationUpdate();
    });
  }

  void stopTracking() {
    _timer?.cancel();
    _isTracking = false;
    _currentTechnicianId = null;
  }

  Future<void> _sendLocationUpdate() async {
    if (_currentTechnicianId == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'technicianId': _currentTechnicianId,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Location updated successfully: ${position.latitude}, ${position.longitude}');
      } else if (response.statusCode == 404) {
        debugPrint('Location endpoint is not available in the current backend.');
      } else {
        debugPrint('Failed to update location. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending location: $e');
      // Retry logic could be implemented here or let the next tick handle it
    }
  }

  // Fetch the latest live location for a specific technician (Useful for Manager side)
  static Future<Map<String, dynamic>?> getLiveLocation(String technicianId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$technicianId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      } else if (response.statusCode == 404) {
        debugPrint('Live location endpoint is not implemented in the current backend.');
      }
    } catch (e) {
      debugPrint('Error fetching live location: $e');
    }
    return null;
  }
}
