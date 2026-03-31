import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

class ApiService {
  final String baseUrl = "http://localhost:5000"; // Use 10.0.2.2 for Android Emulator
  final String? _token;

  ApiService(this._token);

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    if (_token != null) "Authorization": "Bearer $_token",
  };

  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    return jsonDecode(res.body);
  }

  // --- Manager Endpoints ---
  Future<List<Technician>> getTechnicians() async {
    final res = await http.get(Uri.parse("$baseUrl/manager/technicians"), headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];
      return data.map((t) => Technician.fromFirestore(t, t['id'] ?? '')).toList();
    }
    return [];
  }

  Future<List<Job>> getManagerJobs() async {
    final res = await http.get(Uri.parse("$baseUrl/manager/tasks"), headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];
      return data.map((j) => Job.fromFirestore(j, j['id'] ?? '')).toList();
    }
    return [];
  }

  // --- Technician Endpoints ---
  Future<List<Job>> getTechnicianJobs() async {
    final res = await http.get(Uri.parse("$baseUrl/technician/tasks"), headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];
      return data.map((j) => Job.fromFirestore(j, j['id'] ?? '')).toList();
    }
    return [];
  }

  Future<void> updateJobStatus(String jobId, String status, {String? notes}) async {
    await http.patch(
      Uri.parse("$baseUrl/technician/tasks/$jobId/status"),
      headers: _headers,
      body: jsonEncode({"status": status, "notes": notes}),
    );
  }

  Future<void> updateLocation(double lat, double lng, {bool? isOnline}) async {
    await http.patch(
      Uri.parse("$baseUrl/technician/location"),
      headers: _headers,
      body: jsonEncode({
        "lat": lat,
        "lng": lng,
        ... (isOnline != null ? {"isOnline": isOnline} : {}),
      }),
    );
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final session = ref.watch(authProvider);
  return ApiService(session?.token);
});
