import 'package:flutter/foundation.dart';
import 'core/network/api_client.dart';
import 'models.dart';

class DemoData extends ChangeNotifier {
  static final DemoData _instance = DemoData._internal();
  static DemoData get instance => _instance;

  DemoData._internal() {
    _initializeData();
  }

  List<Job> _jobs = [];
  List<Technician> _technicians = [];

  List<Job> get jobs => _jobs;
  List<Technician> get technicians => _technicians;

  int get totalJobs => _jobs.length;
  int get activeJobs => _jobs.where((j) => j.status == JobStatus.inProgress).length;
  int get completedJobs => _jobs.where((j) => j.status == JobStatus.completed).length;
  int get pendingApprovalJobs => _jobs.where((j) => j.status == JobStatus.pendingApproval).length;

  List<Job> get recentJobs {
    List<Job> sorted = List.from(_jobs);
    sorted.sort((a, b) => b.id.compareTo(a.id));
    return sorted.take(2).toList();
  }

  void _initializeData() {
    _jobs = [
      const Job(
        id: "101",
        serviceName: "Network Setup",
        customerName: "Tech Corp",
        customerPhone: "555-011",
        address: "123 Downtown Ave",
        time: "09:00 AM",
        status: JobStatus.pendingApproval,
        technicianName: "Alex Brown",
        assignedBy: "Manager Mike",
        notes: "Customer requested priority installation. Checked all network nodes.",
      ),
      const Job(
        id: "102",
        serviceName: "Pipe Repair",
        customerName: "John Smith",
        customerPhone: "555-012",
        address: "456 Oak St",
        time: "11:00 AM",
        status: JobStatus.inProgress,
        technicianName: "Jamie Doe",
        assignedBy: "Manager Jane",
        notes: "Main pressure valve is leaking.",
      ),
      const Job(
        id: "103",
        serviceName: "AC Service",
        customerName: "Mary Doe",
        customerPhone: "555-013",
        address: "789 Pine Ln",
        time: "01:00 PM",
        status: JobStatus.assigned,
        technicianName: "Chris Wong",
        assignedBy: "Manager Mike",
        notes: "Routine maintenance.",
      ),
      const Job(
        id: "104",
        serviceName: "Wiring Check",
        customerName: "Bob Ross",
        customerPhone: "555-014",
        address: "321 Canvas Ct",
        time: "02:30 PM",
        status: JobStatus.completed,
        technicianName: "Sarah Miller",
        assignedBy: "Manager Jane",
      ),
      const Job(
        id: "105",
        serviceName: "EV Charger Install",
        customerName: "Alice Green",
        customerPhone: "555-999",
        address: "North Hill",
        time: "03:00 PM",
        status: JobStatus.pendingApproval,
        technicianName: "Sarah Miller",
        assignedBy: "Manager Jane",
        notes: "Completed installation, testing voltages.",
      ),
    ];

    _technicians = [
      const Technician(
        id: "T1",
        name: "Alex Brown",
        status: TechnicianStatus.busy,
        currentJobId: "101",
        phone: "555-0101",
        specialty: "Network Engineer",
        assignedManager: "Manager Mike",
      ),
      const Technician(
        id: "T2",
        name: "Jamie Doe",
        status: TechnicianStatus.available,
        phone: "555-0202",
        specialty: "Plumber",
        assignedManager: "Manager Jane",
      ),
      const Technician(
        id: "T3",
        name: "Chris Wong",
        status: TechnicianStatus.offline,
        phone: "555-0303",
        specialty: "HVAC Specialist",
        assignedManager: "Manager Mike",
      ),
      const Technician(
        id: "T4",
        name: "Sarah Miller",
        status: TechnicianStatus.available,
        phone: "555-0404",
        specialty: "Electrician",
        assignedManager: "Manager Jane",
      ),
    ];
  }

  void approveJob(String jobId, ApiClient apiClient, String token) async {
    try {
      await apiClient.patchJson('/manager/tasks/$jobId/status', body: {'status': 'completed'}, token: token);
      _updateJobStatus(jobId, JobStatus.completed);
    } catch (_) {}
  }

  void rejectJob(String jobId, ApiClient apiClient, String token) async {
    try {
      await apiClient.patchJson('/manager/tasks/$jobId/status', body: {'status': 'in_progress'}, token: token);
      _updateJobStatus(jobId, JobStatus.inProgress);
    } catch (_) {}
  }

  void _updateJobStatus(String jobId, JobStatus newStatus) {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      _jobs[index] = _jobs[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void addJob(Job job) {
    _jobs.add(job);
    notifyListeners();
  }

  Future<void> loadFromApi(ApiClient apiClient, String token) async {
    try {
      final resTasks = await apiClient.getJson('/manager/tasks', token: token);
      if (resTasks['success'] == true) {
        final List<dynamic> tData = resTasks['data'];
        _jobs = tData.map((t) {
          final String title = t['title']?.toString() ?? 'Task';
          final String statusStr = t['status']?.toString() ?? 'pending';

          JobStatus status = JobStatus.assigned;
          if (statusStr == 'in_progress') status = JobStatus.inProgress;
          if (statusStr == 'pending_approval' || statusStr == 'pending') status = JobStatus.pendingApproval;
          if (statusStr == 'completed') status = JobStatus.completed;

          final customer = t['assignedBy'] != null ? t['assignedBy']['name']?.toString() : 'Manager';
          final techName = t['assignedTo'] != null ? t['assignedTo']['name']?.toString() : null;
          final techId = t['assignedTo'] != null ? t['assignedTo']['id']?.toString() : null;

          return Job(
            id: t['id']?.toString() ?? '0',
            serviceName: title,
            customerName: customer ?? 'Manager',
            customerPhone: 'N/A',
            address: t['description']?.toString() ?? 'No description',
            time: 'Now',
            status: status,
            technicianName: techName,
            technicianId: techId,
            assignedBy: customer,
          );
        }).toList();
      }

      final resTechs = await apiClient.getJson('/manager/technicians', token: token);
      if (resTechs['success'] == true) {
        final List<dynamic> techData = resTechs['data'];
        _technicians = techData.map((t) {
          TechnicianStatus status = TechnicianStatus.available;
          if (t['status'] == 'offline') status = TechnicianStatus.offline;
          if (t['status'] == 'busy') status = TechnicianStatus.busy;

          return Technician(
            id: t['id']?.toString() ?? '0',
            name: t['name']?.toString() ?? 'Tech',
            status: status,
            phone: t['phone']?.toString() ?? 'N/A',
            specialty: t['specialty']?.toString() ?? 'General Technician',
          );
        }).toList();
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading backend data: $e');
      }
    }
  }
}
