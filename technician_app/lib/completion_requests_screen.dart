import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'demo_data.dart';

class CompletionRequestsScreen extends StatefulWidget {
  const CompletionRequestsScreen({super.key});

  @override
  State<CompletionRequestsScreen> createState() => _CompletionRequestsScreenState();
}

class _CompletionRequestsScreenState extends State<CompletionRequestsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("COMPLETION REQUESTS")),
      body: ListenableBuilder(
        listenable: DemoData.instance,
        builder: (context, _) {
          final requests = DemoData.instance.jobs.where((j) => j.status == JobStatus.pendingApproval).toList();
          return requests.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: requests.length,
                  itemBuilder: (context, index) => _buildRequestCard(context, requests[index]),
                );
        }
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Job job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("JOB #${job.id}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF94A3B8), letterSpacing: 1)),
              StatusChip(status: job.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(job.serviceName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text("Technician: ${job.technicianName}", style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            ],
          ),
          const Divider(height: 48, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(
                child: _buildActionButton("REJECT", const Color(0xFFF43F5E), () {
                  DemoData.instance.rejectJob(job.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job rejected and sent back to technician.")));
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton("APPROVE", const Color(0xFF10B981), () {
                  DemoData.instance.approveJob(job.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job approved and marked as completed.")));
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.done_all_rounded, size: 80, color: Colors.green.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          const Text("No pending requests", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
