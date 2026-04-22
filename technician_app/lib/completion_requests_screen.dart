import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'widgets.dart';
import 'services/api_service.dart';

class CompletionRequestsScreen extends ConsumerStatefulWidget {
  const CompletionRequestsScreen({super.key});

  @override
  ConsumerState<CompletionRequestsScreen> createState() => _CompletionRequestsScreenState();
}

class _CompletionRequestsScreenState extends ConsumerState<CompletionRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text("REQUEST CENTER"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF1E3A8A),
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: const [
            Tab(text: "COMPLETIONS"),
            Tab(text: "EXPENDITURES"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJobsTab(),
          _buildExpensesTab(),
        ],
      ),
    );
  }

  Widget _buildJobsTab() {
     final api = ref.watch(apiServiceProvider);
     return FutureBuilder<List<Job>>(
        future: api.getJobs(status: 'completion_requested'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final pendingJobs = snapshot.data ?? [];
          if (pendingJobs.isEmpty) return _buildEmptyState("No completion requests");
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pendingJobs.length,
            itemBuilder: (context, index) => _buildRequestCard(context, pendingJobs[index]),
          );
        },
      );
  }

  Widget _buildExpensesTab() {
    final api = ref.watch(apiServiceProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: api.getExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final allExpenses = snapshot.data ?? [];
          final pendingExpenses = allExpenses.where((e) => e['status'] == 'pending' || e['status'] == 'pending_approval').toList();
          if (pendingExpenses.isEmpty) return _buildEmptyState("No expenditure requests");
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pendingExpenses.length,
            itemBuilder: (context, index) => _buildExpenseCard(context, pendingExpenses[index]),
          );
        },
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
                child: _buildActionButton("REJECT", const Color(0xFFF43F5E), () => _handleAction(job.id, JobStatus.assigned)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton("APPROVE", const Color(0xFF10B981), () => _showJobDetailDialog(job)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, Map<String, dynamic> exp) {
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
              const Text("EXPENDITURE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF94A3B8), letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text("PENDING", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(exp['description'] ?? 'No Description', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text("\$${exp['amount']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF3B82F6))),
          const Divider(height: 48, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(
                child: _buildActionButton("REJECT", const Color(0xFFF43F5E), () => _handleExpenseAction(exp['id'] ?? exp['_id'], 'rejected')),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton("APPROVE", const Color(0xFF10B981), () => _showExpenseDetailDialog(exp)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showJobDetailDialog(Job job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text("Approve Completion: ${job.serviceName}", style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("Client", job.customerName),
            _buildDetailRow("Location", job.address),
            _buildDetailRow("Technician", job.technicianName ?? 'System'),
            _buildDetailRow("Time Taken", "02:45:00"),
            const SizedBox(height: 16),
            const Text("NOTES:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey)),
            Text(job.notes ?? "Work completed as per specifications. No issues found.", style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAction(job.id, JobStatus.approvedByManager);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("CONFIRM APPROVAL", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetailDialog(Map<String, dynamic> exp) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Expense Approval", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("Description", exp['description']),
            _buildDetailRow("Amount", "\$${exp['amount']}"),
            _buildDetailRow("Category", "Maintenance & Repairs"),
            const SizedBox(height: 16),
            Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)), child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.receipt_long_rounded, size: 40, color: Colors.grey), Text("Receipt Attached", style: TextStyle(color: Colors.grey, fontSize: 12))]))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleExpenseAction(exp['id'] ?? exp['_id'], 'approved');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("APPROVE PAYMENT", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 13)), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 13), overflow: TextOverflow.ellipsis))]),
    );
  }

  Future<void> _handleAction(String jobId, JobStatus newStatus) async {
    try {
      await ref.read(apiServiceProvider).updateJobStatus(jobId, newStatus.name);
      if (mounted) {
        String msg = newStatus == JobStatus.approvedByManager ? "Job approved. Waiting for payment." : "Job rejected and sent back to technician.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _handleExpenseAction(String id, String status) async {
    try {
      await ref.read(apiServiceProvider).updateExpenseStatus(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Expense $status callback.")));
        setState(() {});
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, size: 80, color: Colors.blue.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text(message, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
