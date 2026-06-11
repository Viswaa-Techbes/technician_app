import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'models.dart';
import 'widgets.dart';
import 'job_timer_widget.dart';
import 'services/api_service.dart';
import 'features/job_description/widgets/job_description_section.dart';
import 'features/job_description/screens/add_job_description_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'assign_job_screen.dart';
import 'core/security/rbac_constants.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final Job job;

  const ProjectDetailScreen({super.key, required this.job});

  Future<void> _openGoogleMapsNavigation(BuildContext context) async {
    final double lat = job.latitude ?? 13.0827;
    final double lng = job.longitude ?? 80.2707;
    Uri url;
    if (Platform.isIOS) {
      url = Uri.parse('https://maps.apple.com/?saddr=&daddr=$lat,$lng');
    } else {
      url = Uri.parse('google.navigation:q=$lat,$lng');
      if (!await canLaunchUrl(url)) {
        url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      }
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map navigation application')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider);
    final bool isManager = session?.role == Role.manager;

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
            JobDescriptionSection(projectId: job.id),
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
            _buildSiteLocationSection(context),
            const SizedBox(height: 24),
            _buildTimelineSection(),
            const SizedBox(height: 32),
            // Hide JobTimerWidget (Start Job button) for Managers
            if (!isManager && job.status != JobStatus.assigned)
              JobTimerWidget(
                jobId: job.id,
                initialStatus: job.status.name,
              ),
            const SizedBox(height: 40),
            if (isManager)
              CustomButton(
                label: "ASSIGN TECHNICIAN",
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssignJobScreen()),
                ),
                color: const Color(0xFF2563EB),
                icon: Icons.person_add_rounded,
              ),
            const SizedBox(height: 16),
            if ((job.status == JobStatus.completionRequested || job.status == JobStatus.workUploaded) && isManager)
              CustomButton(
                label: "REVIEW COMPLETION",
                onPressed: () => _showReviewDialog(context, ref),
                color: const Color(0xFF8B5CF6),
                icon: Icons.rate_review_rounded,
              ),
            const SizedBox(height: 16),
            CustomButton(
              label: "ADD JOB DESCRIPTION",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddJobDescriptionScreen(projectId: job.id),
                ),
              ),
              color: const Color(0xFF1E3A8A),
              icon: Icons.note_add_rounded,
            ),
            const SizedBox(height: 16),
            if (!isManager && job.status != JobStatus.completed && job.status != JobStatus.paymentPending && job.status != JobStatus.paymentRequested)
              CustomButton(
                label: "REQUEST PAYMENT",
                onPressed: () => _showPaymentRequestDialog(context, ref),
                color: const Color(0xFF10B981),
                icon: Icons.payments_rounded,
              ),
          ],
        ),
      ),
    );
  }

  void _showPaymentRequestDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController(text: job.price.toString());
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Request Payment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount (INR)"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description (Optional)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              try {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) throw "Enter a valid amount";

                final api = ref.read(apiServiceProvider);
                await api.requestPayment(
                  jobId: job.id,
                  amount: amount,
                  description: descController.text,
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to list
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment requested successfully")));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text("SEND REQUEST"),
          ),
        ],
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
                Text(job.status.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
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
        _buildTimelineItem("Completion Requested", "11:30 AM", job.status == JobStatus.completionRequested || job.status == JobStatus.workUploaded || job.status == JobStatus.approvedByManager || job.status == JobStatus.paymentPending || job.status == JobStatus.paymentDone || job.status == JobStatus.completed),
        _buildTimelineItem("Manager Approved", "11:45 AM", job.status == JobStatus.approvedByManager || job.status == JobStatus.paymentPending || job.status == JobStatus.paymentDone || job.status == JobStatus.completed),
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

  void _showReviewDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Review Completion"),
        content: const Text("Approve or reject this completion request?"),
        actions: [
          TextButton(
            onPressed: () => _handleStatusUpdate(context, ref, 'assigned', "Job rejected and sent back to technician."),
            child: const Text("REJECT", style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.w800)),
          ),
          ElevatedButton(
            onPressed: () => _handleStatusUpdate(context, ref, 'approved_by_manager', "Job approved. Waiting for technician to collect payment."),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStatusUpdate(BuildContext context, WidgetRef ref, String newStatus, String message) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateJobStatus(job.id, newStatus);
      
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Go back to list
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildSiteLocationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PROJECT SITE LOCATION",
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: Color(0xFF94A3B8),
                letterSpacing: 2)),
        const SizedBox(height: 16),
        Container(
          height: 240,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Grid lines
              Positioned.fill(
                child: CustomPaint(painter: _ProjectMapGridPainter()),
              ),
              // Location indicator rings
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF2563EB),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Address chip
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pin_drop_rounded,
                          size: 12, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        job.address.length > 22
                            ? '${job.address.substring(0, 22)}\u2026'
                            : job.address,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Navigation button
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openGoogleMapsNavigation(context),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.near_me_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'NAVIGATION',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const spacing = 28.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    final cx = size.width / 2;
    final cy = size.height / 2 - 20;
    final crossPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.12)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), crossPaint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
