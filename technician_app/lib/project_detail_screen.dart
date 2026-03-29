import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'demo_data.dart';
import 'job_timer_widget.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Job job;

  const ProjectDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("PROJECT #${job.id}"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 32),
            _buildInfoSection("SERVICE DETAILS", [
              _buildInfoRow(Icons.settings_rounded, "Service", job.serviceName),
              _buildInfoRow(Icons.access_time_filled_rounded, "Scheduled", job.time),
              _buildInfoRow(Icons.location_on_rounded, "Address", job.address),
            ]),
            const SizedBox(height: 24),
            _buildInfoSection("STAKEHOLDERS", [
              _buildInfoRow(Icons.person_rounded, "Customer", job.customerName),
              _buildInfoRow(Icons.engineering_rounded, "Technician", job.technicianName ?? "Not Assigned"),
              _buildInfoRow(Icons.manage_accounts_rounded, "Assigned By", job.assignedBy ?? "System"),
            ]),
            if (job.notes != null && job.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildInfoSection("NOTES", [
                Text(job.notes!, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569), fontSize: 14, height: 1.5)),
              ]),
            ],
            const SizedBox(height: 24),
            _buildTimelineSection(),
            const SizedBox(height: 32),
            if (job.status != JobStatus.assigned)
              JobTimerWidget(
                jobId: job.id,
                initialStatus: job.status.name,
              ),
            const SizedBox(height: 40),
            if (job.status == JobStatus.pendingApproval)
              CustomButton(
                label: "REVIEW COMPLETION",
                onPressed: () => _showReviewDialog(context),
                color: const Color(0xFF8B5CF6),
                icon: Icons.rate_review_rounded,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CURRENT STATUS", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), fontSize: 11, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(job.status.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1E293B))),
              ],
            ),
          ),
          StatusChip(status: job.status),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 2)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(children: children.expand((w) => [w, const SizedBox(height: 16)]).toList()..removeLast()),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PROJECT TIMELINE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 2)),
        const SizedBox(height: 16),
        _buildTimelineItem("Job Assigned", "09:00 AM", true),
        _buildTimelineItem("Technician Started", "09:15 AM", job.status != JobStatus.assigned),
        _buildTimelineItem("Completion Requested", "11:30 AM", job.status == JobStatus.pendingApproval || job.status == JobStatus.completed),
        _buildTimelineItem("Manager Approved", "11:45 AM", job.status == JobStatus.completed),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: isDone ? const Color(0xFF1E293B) : const Color(0xFF94A3B8))),
                    Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Review Completion"),
        content: const Text("Approve or reject this completion request?"),
        actions: [
          TextButton(
            onPressed: () {
              DemoData.instance.rejectJob(job.id);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job rejected and sent back to technician.")));
            },
            child: const Text("REJECT", style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.w800)),
          ),
          ElevatedButton(
            onPressed: () {
              DemoData.instance.approveJob(job.id);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job approved and marked as completed.")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
