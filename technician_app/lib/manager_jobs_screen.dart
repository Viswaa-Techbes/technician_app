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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("PROJECT REPOSITORY"),
          bottom: const TabBar(
            labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            indicatorColor: Color(0xFF1E3A8A),
            indicatorWeight: 4,
            tabs: [
              Tab(text: "ASSIGNED"),
              Tab(text: "ACTIVE"),
              Tab(text: "DONE"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildJobsList([JobStatus.assigned]),
            _buildJobsList([JobStatus.inProgress]),
            _buildJobsList([JobStatus.completed, JobStatus.pendingApproval]),
          ],
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
      ),
    );
  }

  Widget _buildJobsList(List<JobStatus> statuses) {
    if (MockDataService.useMock) {
      return FutureBuilder<List<Job>>(
        future: MockDataService().getJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final allJobs = snapshot.data ?? [];
          final filtered = allJobs.where((j) => statuses.contains(j.status)).toList();
          if (filtered.isEmpty) return _buildEmptyState();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            itemCount: filtered.length,
            itemBuilder: (context, index) => JobCard(
              job: filtered[index],
              index: index,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailScreen(job: filtered[index]))),
            ),
          );
        },
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('projects').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        final allJobs = docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return Job(
            id: doc.id,
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
        }).toList();
        final filtered = allJobs.where((j) => statuses.contains(j.status)).toList();
        if (filtered.isEmpty) return _buildEmptyState();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          itemCount: filtered.length,
          itemBuilder: (context, index) => JobCard(
            job: filtered[index],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailScreen(job: filtered[index]))),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No projects found", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)));
  }
}
