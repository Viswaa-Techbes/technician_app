import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

import '../core/network/api_config.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl; 
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

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  // --- Dashboard Endpoints ---
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(Uri.parse("$baseUrl/admin/dashboard"), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body)['data'] ?? {};
    return {};
  }

  // --- Job Endpoints ---
  Future<List<Job>> getJobs({String? status}) async {
    final uri = Uri.parse("$baseUrl/jobs").replace(queryParameters: {
      if (status != null) 'status': status,
    });
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];
      return data.map((j) => Job.fromFirestore(j, j['id'] ?? j['_id'] ?? '')).toList();
    }
    return [];
  }

  Future<void> assignJob(String jobId, String technicianId) async {
    await http.post(
      Uri.parse("$baseUrl/jobs/assign"),
      headers: _headers,
      body: jsonEncode({"jobId": jobId, "technicianId": technicianId}),
    );
  }

  Future<void> updateJobStatus(String jobId, String status, {String? notes}) async {
    await http.patch(
      Uri.parse("$baseUrl/technician/tasks/$jobId/status"),
      headers: _headers,
      body: jsonEncode({"status": status, "notes": notes}),
    );
  }

  // --- Technician Endpoints ---
  Future<List<Technician>> getTechnicians() async {
    final res = await http.get(Uri.parse("$baseUrl/technicians"), headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];
      return data.map((t) => Technician.fromFirestore(t, t['id'] ?? t['_id'] ?? '')).toList();
    }
    return [];
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

  // --- Expense Endpoints ---
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final res = await http.get(Uri.parse("$baseUrl/expenses"), headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(json['data'] ?? []);
    }
    return [];
  }

  Future<void> submitExpense(double amount, String description, {String? jobId}) async {
    await http.post(
      Uri.parse("$baseUrl/expenses"),
      headers: _headers,
      body: jsonEncode({
        "amount": amount,
        "description": description,
        if (jobId != null) "jobId": jobId,
      }),
    );
  }

  Future<void> updateExpenseStatus(String id, String status) async {
    await http.patch(
      Uri.parse("$baseUrl/expenses/$id/status"),
      headers: _headers,
      body: jsonEncode({"status": status}),
    );
  }

  // --- Review Endpoints ---
  Future<List<Map<String, dynamic>>> getReviews() async {
    final res = await http.get(Uri.parse("$baseUrl/reviews"), headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(json['data'] ?? []);
    }
    return [];
  }

  Future<void> submitReview(double rating, String comment, String technicianId, {String? jobId}) async {
    await http.post(
      Uri.parse("$baseUrl/reviews"),
      headers: _headers,
      body: jsonEncode({
        "rating": rating,
        "comment": comment,
        "technicianId": technicianId,
        if (jobId != null) "jobId": jobId,
      }),
    );
  }

  // --- Notification Endpoints ---
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final res = await http.get(Uri.parse("$baseUrl/notifications"), headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(json['data'] ?? []);
    }
    return [];
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final session = ref.watch(authProvider);
  return ApiService(session?.token);
});
