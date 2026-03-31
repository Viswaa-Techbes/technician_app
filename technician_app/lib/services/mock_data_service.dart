import 'dart:async';
import '../models.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // In-memory data
  final List<Technician> _technicians = [
    Technician(id: 'tech1', name: 'John Tech (Online)', email: 'john@techbes.com', status: TechnicianStatus.available, isOnline: true, phone: '555-0101'),
    Technician(id: 'tech2', name: 'Sarah Tech (Available)', email: 'sarah@techbes.com', status: TechnicianStatus.available, isOnline: false, phone: '555-0102'),
    Technician(id: 'tech3', name: 'Mike Tech (Offline)', email: 'mike@techbes.com', status: TechnicianStatus.offline, isOnline: false, phone: '555-0103'),
  ];

  final List<Job> _jobs = [
    Job(
      id: 'jobA',
      serviceName: 'Project A: Network Audit',
      customerName: 'Global Corp',
      customerPhone: '123456789',
      address: 'Office 101, Tech Park',
      time: '09:00 AM',
      status: JobStatus.assigned,
      technicianId: 'tech1',
      technicianName: 'John Tech (Online)',
    ),
    Job(
      id: 'jobB',
      serviceName: 'Project B: Server Setup',
      customerName: 'Retail Inc',
      customerPhone: '987654321',
      address: 'Main St 500',
      time: '02:00 PM',
      status: JobStatus.assigned,
      technicianId: 'tech2',
      technicianName: 'Sarah Tech (Available)',
    ),
  ];

  final List<Map<String, dynamic>> _expenses = [
    {'id': 'exp1', 'amount': 150.0, 'description': 'Fuel and Tolls', 'status': 'pending', 'techId': 'tech1'},
    {'id': 'exp2', 'amount': 45.0, 'description': 'Project Supplies', 'status': 'approved', 'techId': 'tech2'},
  ];

  final List<Map<String, dynamic>> _reviews = [
    {'id': 'rev1', 'rating': 4.5, 'comment': 'Excellent work!', 'jobId': 'jobA'},
    {'id': 'rev2', 'rating': 5.0, 'comment': 'Highly professional.', 'jobId': 'jobB'},
  ];

  // Logic functions
  Future<List<Technician>> getTechnicians() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _technicians;
  }

  Future<List<Job>> getJobs() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _jobs;
  }

  Future<void> assignJob(String jobId, String techId, String techName) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      _jobs[index] = _jobs[index].copyWith(
        technicianId: techId,
        technicianName: techName,
        status: JobStatus.assigned,
      );
    }
  }

  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      _jobs[index] = _jobs[index].copyWith(status: status);
    }
  }

  Future<void> submitReview(String jobId, int rating, String comment) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _reviews.add({'id': 'rev${_reviews.length + 1}', 'rating': rating.toDouble(), 'comment': comment, 'jobId': jobId});
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _expenses;
  }

  Future<void> approveExpense(String expId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _expenses.indexWhere((e) => e['id'] == expId);
    if (index != -1) {
      _expenses[index]['status'] = 'approved';
    }
  }

  Future<void> addExpense(double amount, String desc, String techId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _expenses.add({'id': 'exp${_expenses.length + 1}', 'amount': amount, 'description': desc, 'status': 'pending', 'techId': techId});
  }

  // To toggle mock mode in the future if needed
  static bool useMock = true; 
}
