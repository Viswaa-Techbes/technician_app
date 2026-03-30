import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'widgets.dart';
import 'job_detail_screen.dart';
import 'core/network/api_client.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Job> _allJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final session = ref.read(authProvider);

      final tasksResp = await apiClient.getJson('/technician/tasks', token: session?.token);
      final tasks = tasksResp['data'] as List<dynamic>? ?? [];
      
      final parsedJobs = tasks.map((t) {
        JobStatus status = JobStatus.assigned;
        if (t['status'] == 'in_progress') status = JobStatus.inProgress;
        if (t['status'] == 'completed') status = JobStatus.completed;
        if (t['status'] == 'pending') status = JobStatus.pendingApproval;

        return Job(
          id: t['id']?.toString() ?? '',
          serviceName: t['title'] ?? 'Task',
          customerName: t['assignedBy'] != null ? t['assignedBy']['name'] : 'System',
          customerPhone: 'N/A',
          address: 'See Notes',
          time: 'Anytime',
          status: status,
          notes: t['description'] ?? '',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _allJobs = parsedJobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : TabBarView(
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
