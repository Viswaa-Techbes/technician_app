import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  Future<Map<String, dynamic>> login(String mobileNumber, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobileNumber": mobileNumber, "password": password}),
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
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    debugPrint('[ApiService] GET $baseUrl/auth/me');
    final res = await http.get(Uri.parse("$baseUrl/auth/me"), headers: _headers);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    debugPrint('[ApiService] auth/me response (${res.statusCode}): $json');
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to fetch current user profile');
    }
    return Map<String, dynamic>.from(json['data'] ?? <String, dynamic>{});
  }

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

  Future<Job> createJob(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/jobs"),
      headers: _headers,
      body: jsonEncode(data),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to create job');
    }

    final job = (json['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    return Job.fromFirestore(job, job['id'] ?? job['_id'] ?? '');
  }

  Future<void> requestPayment({
    required String jobId,
    required double amount,
    String? description,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/v2/payment/request"),
      headers: _headers,
      body: jsonEncode({
        'jobId': jobId,
        'amount': amount,
        if (description != null) 'description': description,
      }),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to request payment');
    }
  }

  Future<void> assignJob(String jobId, String technicianId) async {
    await http.post(
      Uri.parse("$baseUrl/jobs/assign"),
      headers: _headers,
      body: jsonEncode({"jobId": jobId, "technicianId": technicianId}),
    );
  }

  Future<void> updateJobStatus(String jobId, String status, {String? notes, List<String>? attachments}) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/technician/tasks/$jobId/status"),
      headers: _headers,
      body: jsonEncode({"status": status, "notes": notes, "attachments": attachments}),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to update job status');
    }
  }

  // --- Technician Endpoints ---
  Future<List<Technician>> getTechnicians() async {
    debugPrint('[ApiService] GET $baseUrl/technicians');
    final res = await http.get(Uri.parse("$baseUrl/technicians"), headers: _headers);
    debugPrint('[ApiService] getTechnicians response (${res.statusCode}): ${res.body}');
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];
      return data.map((t) => Technician.fromFirestore(t, t['id'] ?? t['_id'] ?? '')).toList();
    }
    return [];
  }

  Future<List<Technician>> getTrackingData() async {
    debugPrint('[ApiService] GET $baseUrl/api/v2/admin/tracking');
    final res = await http.get(Uri.parse("$baseUrl/api/v2/admin/tracking"), headers: _headers);
    debugPrint('[ApiService] getTrackingData response (${res.statusCode})');
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];
      return data.map((t) => Technician.fromFirestore(t, t['technicianId'] ?? t['id'] ?? t['_id'] ?? '')).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> updateTechnicianStatus({
    required String userId,
    required bool isOnline,
    double? lat,
    double? lng,
  }) async {
    final payload = <String, dynamic>{
      'userId': userId,
      'isOnline': isOnline,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };

    debugPrint('[ApiService] POST $baseUrl/technician/update-status payload=$payload');
    final res = await http.post(
      Uri.parse("$baseUrl/technician/update-status"),
      headers: _headers,
      body: jsonEncode(payload),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    debugPrint('[ApiService] updateTechnicianStatus response (${res.statusCode}): $json');

    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to update technician status');
    }

    return Map<String, dynamic>.from(json['data'] ?? <String, dynamic>{});
  }

  Future<void> updateLocation(double lat, double lng, {bool? isOnline}) async {
    final payload = {
      "lat": lat,
      "lng": lng,
      if (isOnline != null) "isOnline": isOnline,
    };
    debugPrint('[ApiService] POST $baseUrl/api/v2/location/update payload=$payload');
    final res = await http.post(
      Uri.parse("$baseUrl/api/v2/location/update"),
      headers: _headers,
      body: jsonEncode(payload),
    );
    debugPrint('[ApiService] updateLocation response (${res.statusCode}): ${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Failed to update location');
    }
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

  Future<void> updateFcmToken(String fcmToken) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/fcm-token"),
      headers: _headers,
      body: jsonEncode({"fcmToken": fcmToken}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to update FCM token');
    }
  }
  // --- Attendance Endpoints ---
  Future<void> markAttendance() async {
    debugPrint('[ApiService] POST $baseUrl/attendance/mark-attendance');
    final res = await http.post(
      Uri.parse("$baseUrl/attendance/mark-attendance"),
      headers: _headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('[ApiService] Failed to mark attendance: ${res.body}');
    }
  }

  Future<void> markLogout() async {
    debugPrint('[ApiService] POST $baseUrl/attendance/mark-logout');
    final res = await http.post(
      Uri.parse("$baseUrl/attendance/mark-logout"),
      headers: _headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('[ApiService] Failed to mark logout: ${res.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllAttendance() async {
    final res = await http.get(Uri.parse("$baseUrl/attendance/all"), headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(json['data'] ?? []);
    }
    return [];
  }

  Future<List<String>> uploadFiles(List<Map<String, dynamic>> filesData) async {
    final uri = Uri.parse("$baseUrl/api/v2/upload/multiple");
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers..remove('Content-Type'));

    for (var fileData in filesData) {
      if (fileData['bytes'] != null && fileData['name'] != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'files',
          fileData['bytes'],
          filename: fileData['name'],
        ));
      }
    }

    final res = await request.send();
    final resBody = await res.stream.bytesToString();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(resBody);
      if (json['success'] == true) {
        final List uploaded = json['files'] ?? [];
        return uploaded.map<String>((f) => f['fileUrl']).toList();
      }
    }
    throw Exception('Failed to upload files: $resBody');
  }

  // --- Phase 2 Dispatch Endpoints ---
  Future<Map<String, dynamic>> acceptJobRequest(String jobId) async {
    debugPrint('[ApiService] POST $baseUrl/api/v2/dispatch/accept/$jobId');
    final res = await http.post(
      Uri.parse("$baseUrl/api/v2/dispatch/accept/$jobId"),
      headers: _headers,
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to accept job request');
    }
    return json;
  }

  Future<Map<String, dynamic>> rejectJobRequest(String jobId, {String? reason}) async {
    debugPrint('[ApiService] POST $baseUrl/api/v2/dispatch/reject/$jobId');
    final res = await http.post(
      Uri.parse("$baseUrl/api/v2/dispatch/reject/$jobId"),
      headers: _headers,
      body: jsonEncode({"reason": reason ?? ''}),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to reject job request');
    }
    return json;
  }

  Future<Map<String, dynamic>> updateAvailabilityStatus(String status) async {
    debugPrint('[ApiService] PUT $baseUrl/api/v2/dispatch/availability status=$status');
    final res = await http.put(
      Uri.parse("$baseUrl/api/v2/dispatch/availability"),
      headers: _headers,
      body: jsonEncode({"status": status}),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to update availability');
    }
    return json;
  }

  Future<void> updateLiveLocation(double lat, double lng) async {
    debugPrint('[ApiService] PUT $baseUrl/api/v2/dispatch/location lat=$lat, lng=$lng');
    final res = await http.put(
      Uri.parse("$baseUrl/api/v2/dispatch/location"),
      headers: _headers,
      body: jsonEncode({"lat": lat, "lng": lng}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Failed to update location');
    }
  }

  Future<List<Map<String, dynamic>>> getJobRequests() async {
    debugPrint('[ApiService] GET $baseUrl/api/v2/dispatch/my-requests');
    final res = await http.get(Uri.parse("$baseUrl/api/v2/dispatch/my-requests"), headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<Map<String, dynamic>> techCancelJob(String jobId, String reason) async {
    debugPrint('[ApiService] POST $baseUrl/api/v2/dispatch/tech-cancel/$jobId reason=$reason');
    final res = await http.post(
      Uri.parse("$baseUrl/api/v2/dispatch/tech-cancel/$jobId"),
      headers: _headers,
      body: jsonEncode({"reason": reason}),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to cancel job');
    }
    return json;
  }

  // --- OTP Start / Complete Methods ---
  Future<Map<String, dynamic>> requestStartOtp(String jobId) async {
    debugPrint('[ApiService] POST $baseUrl/api/v2/dispatch/otp/start/$jobId');
    final res = await http.post(
      Uri.parse("$baseUrl/api/v2/dispatch/otp/start/$jobId"),
      headers: _headers,
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to request start OTP');
    }
    return json;
  }

  Future<Map<String, dynamic>> verifyStartOtp(String jobId, String otp) async {
    debugPrint('[ApiService] POST $baseUrl/api/v2/dispatch/otp/start/$jobId/verify');
    final res = await http.post(
      Uri.parse("$baseUrl/api/v2/dispatch/otp/start/$jobId/verify"),
      headers: _headers,
      body: jsonEncode({"otp": otp}),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to verify start OTP');
    }
    return json;
  }

  Future<Map<String, dynamic>> requestCompleteOtp(String jobId) async {
    debugPrint('[ApiService] POST $baseUrl/api/v2/dispatch/otp/complete/$jobId');
    final res = await http.post(
      Uri.parse("$baseUrl/api/v2/dispatch/otp/complete/$jobId"),
      headers: _headers,
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to request complete OTP');
    }
    return json;
  }

  Future<Map<String, dynamic>> verifyCompleteOtp(String jobId, String otp) async {
    debugPrint('[ApiService] POST $baseUrl/api/v2/dispatch/otp/complete/$jobId/verify');
    final res = await http.post(
      Uri.parse("$baseUrl/api/v2/dispatch/otp/complete/$jobId/verify"),
      headers: _headers,
      body: jsonEncode({"otp": otp}),
    );
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to verify complete OTP');
    }
    return json;
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final session = ref.watch(authProvider);
  return ApiService(session?.token);
});
