import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'widgets.dart';

class CompletionRequestsScreen extends ConsumerStatefulWidget {
  const CompletionRequestsScreen({super.key});

  @override
  ConsumerState<CompletionRequestsScreen> createState() => _CompletionRequestsScreenState();
}

class _CompletionRequestsScreenState extends ConsumerState<CompletionRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("COMPLETION REQUESTS")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('projects')
            .where('status', isEqualTo: 'pendingApproval')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;
              final job = Job(
                id: docs[index].id,
                serviceName: d['serviceName'] ?? 'No Service',
                customerName: d['customerName'] ?? 'No Customer',
                customerPhone: d['customerPhone'] ?? '',
                address: d['address'] ?? '',
                time: d['time'] ?? '',
                status: JobStatus.pendingApproval,
                technicianName: d['technicianName'],
                technicianId: d['technicianId'],
              );
              return _buildRequestCard(context, job);
            },
          );
        },
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
              Text("Technician: ${job.technicianName ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            ],
          ),
          const Divider(height: 48, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(
                child: _buildActionButton("REJECT", const Color(0xFFF43F5E), () => _handleAction(job.id, 'assigned')),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton("APPROVE", const Color(0xFF10B981), () => _handleAction(job.id, 'completed')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String jobId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('projects').doc(jobId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        String msg = newStatus == 'completed' ? "Job approved and marked as completed." : "Job rejected and sent back to technician.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
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
