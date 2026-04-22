import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'widgets.dart';
import 'services/api_service.dart';
import 'job_detail_screen.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
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
    final api = ref.watch(apiServiceProvider);
    
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
      body: FutureBuilder<List<Job>>(
        future: api.getJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allJobs = snapshot.data ?? [];
          return TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildJobList(allJobs, [JobStatus.assigned]),
              _buildJobList(allJobs, [
                JobStatus.started,
                JobStatus.workUploaded,
                JobStatus.completionRequested,
                JobStatus.approvedByManager,
                JobStatus.paymentPending
              ]),
              _buildJobList(allJobs, [JobStatus.paymentDone, JobStatus.completed]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJobList(List<Job> allJobs, List<JobStatus> statuses) {
    final filtered = allJobs.where((j) => statuses.contains(j.status)).toList();
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
