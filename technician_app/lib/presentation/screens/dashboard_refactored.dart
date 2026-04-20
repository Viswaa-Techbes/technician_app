import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/jobs_provider.dart';
import '../../domain/entities/job_entity.dart';
import '../../services/connectivity_service.dart';
import '../../models.dart';

class DashboardRefactored extends ConsumerWidget {
  const DashboardRefactored({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsState = ref.watch(jobsNotifierProvider);
    final connectivity = ref.watch(connectivityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Refactored Dashboard", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          IconButton(
            onPressed: () => ref.read(jobsNotifierProvider.notifier).refreshJobs(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          if (connectivity == ConnectivityStatus.isDisconnected)
            _buildOfflineBanner(),
            
          Expanded(
            child: jobsState.when(
              data: (jobs) => _buildJobList(jobs, ref),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(e.toString(), ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList(List<JobEntity> jobs, WidgetRef ref) {
    if (jobs.isEmpty) {
      return const Center(child: Text("No assignments found."));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(jobsNotifierProvider.notifier).refreshJobs(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _JobItem(job: job);
        },
      ),
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(jobsNotifierProvider.notifier).getJobs(),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.redAccent,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Text(
        "Offline Mode - No Internet Connection",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _JobItem extends StatelessWidget {
  final JobEntity job;
  const _JobItem({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(job.serviceName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _StatusBadge(status: job.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(job.customerName, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(job.address, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("INR ${job.price}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                TextButton(
                  onPressed: () {}, // Navigate to detail
                  child: const Text("VIEW DETAILS"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final JobStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == JobStatus.inProgress) color = Colors.orange;
    if (status == JobStatus.completed) color = Colors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
