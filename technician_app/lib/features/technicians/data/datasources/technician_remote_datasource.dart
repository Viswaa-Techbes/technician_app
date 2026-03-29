import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/technician_model.dart';
import '../../domain/entities/technician_entity.dart';
import '../../domain/repositories/technician_repository.dart';

/// Plug in your real base URL here — swap for Node.js / Firebase endpoint.
const _kBaseUrl = 'https://api.techbes.com/v1';

abstract class TechnicianRemoteDataSource {
  Future<List<TechnicianModel>> fetchTechnicians(GetTechniciansParams params);
  Future<List<String>> fetchSkillCategories();
}

/// Production implementation — makes real HTTP requests.
/// Replace [_kBaseUrl] with your backend URL and add auth headers as needed.
class TechnicianRemoteDataSourceImpl implements TechnicianRemoteDataSource {
  final http.Client _client;
  final String baseUrl;

  const TechnicianRemoteDataSourceImpl({
    required http.Client client,
    this.baseUrl = _kBaseUrl,
  }) : _client = client;

  @override
  Future<List<TechnicianModel>> fetchTechnicians(GetTechniciansParams params) async {
    final queryParams = <String, String>{
      'page': params.page.toString(),
      'limit': params.pageSize.toString(),
      if (params.searchQuery != null && params.searchQuery!.isNotEmpty)
        'search': params.searchQuery!,
      if (params.skillFilter != null && params.skillFilter!.isNotEmpty)
        'skill': params.skillFilter!,
      if (params.statusFilter != null)
        'status': params.statusFilter!.label,
    };

    final uri = Uri.parse('$baseUrl/technicians').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['technicians'] as List<dynamic>? ?? data['data'] as List<dynamic>;
      return list.map((e) => TechnicianModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw TechnicianApiException('Server error: ${response.statusCode}', response.statusCode);
    }
  }

  @override
  Future<List<String>> fetchSkillCategories() async {
    final uri = Uri.parse('$baseUrl/technicians/skills');
    final response = await _client.get(uri, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return List<String>.from(data['skills'] as List<dynamic>);
    } else {
      throw TechnicianApiException('Server error: ${response.statusCode}', response.statusCode);
    }
  }
}

/// Mock data source — used when backend is not yet available.
class TechnicianMockDataSource implements TechnicianRemoteDataSource {
  static const _mockTechnicians = [
    {'id': 't1', 'name': 'Arjun Menon', 'skill': 'CCTV Installation', 'experience': '5 yrs', 'status': 'On Job', 'assignedTasksCount': 3, 'phone': '+91 98001 11234', 'rating': 4.8},
    {'id': 't2', 'name': 'Suresh Kumar', 'skill': 'Laptop / Desktop', 'experience': '4 yrs', 'status': 'On Job', 'assignedTasksCount': 2, 'phone': '+91 97001 22345', 'rating': 4.6},
    {'id': 't3', 'name': 'Vikram Reddy', 'skill': 'Networking', 'experience': '6 yrs', 'status': 'Available', 'assignedTasksCount': 0, 'phone': '+91 96001 33456', 'rating': 4.7},
    {'id': 't4', 'name': 'Deepa Thomas', 'skill': 'AMC Maintenance', 'experience': '3 yrs', 'status': 'Available', 'assignedTasksCount': 0, 'phone': '+91 95001 44567', 'rating': 4.5},
    {'id': 't5', 'name': 'Manoj Pillai', 'skill': 'CCTV Installation', 'experience': '2 yrs', 'status': 'Offline', 'assignedTasksCount': 0, 'phone': '+91 94001 55678', 'rating': 4.3},
    {'id': 't6', 'name': 'Preethi Srinivas', 'skill': 'Networking', 'experience': '7 yrs', 'status': 'On Job', 'assignedTasksCount': 3, 'phone': '+91 93001 66789', 'rating': 4.9},
    {'id': 't7', 'name': 'Ravi Shankar', 'skill': 'Laptop / Desktop', 'experience': '3 yrs', 'status': 'Available', 'assignedTasksCount': 1, 'phone': '+91 92001 77890', 'rating': 4.4},
    {'id': 't8', 'name': 'Meena Krishnan', 'skill': 'AMC Maintenance', 'experience': '5 yrs', 'status': 'Offline', 'assignedTasksCount': 0, 'phone': '+91 91001 88901', 'rating': 4.2},
    {'id': 't9', 'name': 'Karthik Nair', 'skill': 'CCTV Installation', 'experience': '4 yrs', 'status': 'Available', 'assignedTasksCount': 2, 'phone': '+91 90001 99012', 'rating': 4.6},
    {'id': 't10', 'name': 'Divya Ramesh', 'skill': 'Networking', 'experience': '2 yrs', 'status': 'On Job', 'assignedTasksCount': 1, 'phone': '+91 89001 10123', 'rating': 4.1},
    {'id': 't11', 'name': 'Anand Babu', 'skill': 'Laptop / Desktop', 'experience': '8 yrs', 'status': 'Available', 'assignedTasksCount': 0, 'phone': '+91 88001 21234', 'rating': 4.9},
    {'id': 't12', 'name': 'Lakshmi Iyer', 'skill': 'AMC Maintenance', 'experience': '6 yrs', 'status': 'On Job', 'assignedTasksCount': 4, 'phone': '+91 87001 32345', 'rating': 4.7},
  ];

  @override
  Future<List<TechnicianModel>> fetchTechnicians(GetTechniciansParams params) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    var results = _mockTechnicians.map((e) => TechnicianModel.fromJson(Map<String, dynamic>.from(e))).toList();

    // Apply search filter
    if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
      final q = params.searchQuery!.toLowerCase();
      results = results.where((t) => t.name.toLowerCase().contains(q) || t.skill.toLowerCase().contains(q)).toList();
    }

    // Apply skill filter
    if (params.skillFilter != null && params.skillFilter!.isNotEmpty) {
      results = results.where((t) => t.skill == params.skillFilter).toList();
    }

    // Apply status filter
    if (params.statusFilter != null) {
      results = results.where((t) => t.status.toLowerCase() == params.statusFilter!.label.toLowerCase()).toList();
    }

    // Pagination
    final start = (params.page - 1) * params.pageSize;
    final end = (start + params.pageSize).clamp(0, results.length);
    return start >= results.length ? [] : results.sublist(start, end);
  }

  @override
  Future<List<String>> fetchSkillCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ['CCTV Installation', 'Laptop / Desktop', 'Networking', 'AMC Maintenance'];
  }
}

class TechnicianApiException implements Exception {
  final String message;
  final int? statusCode;
  const TechnicianApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'TechnicianApiException: $message (HTTP $statusCode)';
}
