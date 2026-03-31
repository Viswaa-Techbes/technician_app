import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets.dart';
import 'models.dart';
import 'services/mock_data_service.dart';
import 'project_detail_screen.dart';
import 'assign_job_screen.dart';

class ManagerJobsScreen extends StatelessWidget {
  const ManagerJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("PROJECT REPOSITORY")),
      body: MockDataService.useMock 
        ? FutureBuilder<List<Job>>(
            future: MockDataService().getJobs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final allJobs = snapshot.data ?? [];
              if (allJobs.isEmpty) return _buildEmptyState();
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                itemCount: allJobs.length,
                itemBuilder: (context, index) {
                  final job = allJobs[index];
                  return JobCard(
                    job: job,
                    index: index,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailScreen(job: job))),
                  );
                },
              );
            },
          )
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('projects').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final d = docs[index].data() as Map<String, dynamic>;
                  final job = Job(
                    id: docs[index].id,
                    serviceName: d['serviceName'] ?? 'No Service',
                    customerName: d['customerName'] ?? 'No Customer',
                    customerPhone: d['customerPhone'] ?? '',
                    address: d['address'] ?? '',
                    time: d['time'] ?? 'N/A',
                    status: JobStatus.values.firstWhere((e) => e.name == d['status'], orElse: () => JobStatus.assigned),
                    price: (d['price'] ?? 0.0).toDouble(),
                    technicianName: d['technicianName'],
                    technicianId: d['technicianId'],
                  );
                  return JobCard(
                    job: job,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailScreen(job: job))),
                  );
                },
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AssignJobScreen())),
        label: const Text("CREATE PROJECT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        icon: const Icon(Icons.add_circle_outline_rounded),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No projects found", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)));
  }
}
