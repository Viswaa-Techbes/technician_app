import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Job> _allJobs = [
    const Job(id: '001', serviceName: 'CCTV Installation', customerName: 'John Smith', customerPhone: '+1 555-010-9988', address: '123 Main St', time: '10:30 AM', status: JobStatus.inProgress),
    const Job(id: '002', serviceName: 'AC Repair', customerName: 'Sarah Johnson', customerPhone: '+1 555-020-7766', address: '456 Oak Ave', time: '01:00 PM', status: JobStatus.assigned),
    const Job(id: '003', serviceName: 'Electrical Fix', customerName: 'Mike Davis', customerPhone: '+1 555-030-5544', address: '789 Pine Rd', time: '03:30 PM', status: JobStatus.assigned),
    const Job(id: '004', serviceName: 'Plumbing', customerName: 'Emily Brown', customerPhone: '+1 555-040-3322', address: '321 Elm St', time: '05:00 PM', status: JobStatus.completed),
    const Job(id: '005', serviceName: 'Network Setup', customerName: 'Robert Wilson', customerPhone: '+1 555-050-1100', address: '555 Cedar Ln', time: '09:00 AM', status: JobStatus.completed),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ALL PROJECTS'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF1E3A8A),
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          tabs: const [
            Tab(text: 'ASSIGNED'),
            Tab(text: 'ACTIVE'),
            Tab(text: 'DONE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildJobList(JobStatus.assigned),
          _buildJobList(JobStatus.inProgress),
          _buildJobList(JobStatus.completed),
        ],
      ),
    );
  }

  Widget _buildJobList(JobStatus status) {
    final filtered = _allJobs.where((j) => j.status == status).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)],
              ),
              child: Icon(Icons.inventory_2_rounded, size: 64, color: Colors.blue.shade100),
            ),
            const SizedBox(height: 24),
            Text(
              "No projects found",
              style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      itemCount: filtered.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) => JobCard(
        index: index,
        job: filtered[index],
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
              opacity: animation,
              child: JobDetailScreen(job: filtered[index]),
            ),
          ),
        ),
      ),
    );
  }
}
