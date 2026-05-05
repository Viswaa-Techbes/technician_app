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

  Future<Map<String, dynamic>> createOrder({
    required int amountInPaise,
    required String description,
    String? receipt,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/create-order"),
      headers: _headers,
      body: jsonEncode({
        'amount': amountInPaise,
        'description': description,
        if (receipt != null && receipt.isNotEmpty) 'receipt': receipt,
      }),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to create Razorpay order');
    }

    return Map<String, dynamic>.from(json['data'] ?? <String, dynamic>{});
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String jobId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/verify-payment"),
      headers: _headers,
      body: jsonEncode({
        'jobId': jobId,
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      }),
    );

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to verify payment');
    }

    return Map<String, dynamic>.from(json['data'] ?? <String, dynamic>{});
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
    await http.patch(
      Uri.parse("$baseUrl/technician/tasks/$jobId/status"),
      headers: _headers,
      body: jsonEncode({"status": status, "notes": notes, "attachments": attachments}),
    );
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
    throw Exception('Failed to upload files');
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final session = ref.watch(authProvider);
  return ApiService(session?.token);
});
