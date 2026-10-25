import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/apartment_provider.dart';
import '../../../models/society_ticket_model.dart';

class ComplaintDetailsScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const ComplaintDetailsScreen({super.key, required this.ticketId});

  @override
  ConsumerState<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends ConsumerState<ComplaintDetailsScreen> {
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _reopenReasonController = TextEditingController();
  final TextEditingController _internalNoteController = TextEditingController();
  final TextEditingController _resolutionNotesController = TextEditingController();

  bool _isSendingReply = false;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(apartmentProvider.notifier).loadTicketDetails(widget.ticketId));
  }

  @override
  void dispose() {
    _replyController.dispose();
    _reopenReasonController.dispose();
    _internalNoteController.dispose();
    _resolutionNotesController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return Colors.blue;
      case 'Acknowledged':
        return Colors.indigo;
      case 'Assigned':
        return Colors.purple;
      case 'In Progress':
        return Colors.orange;
      case 'Resolved':
        return Colors.green;
      case 'Closed':
        return Colors.grey;
      case 'Reopened':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _handleSendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingReply = true);
    try {
      await ref.read(apartmentProvider.notifier).sendReply(widget.ticketId, text);
      _replyController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingReply = false);
    }
  }

  void _showUpdateStatusSheet(SocietyTicketModel ticket) {
    final statuses = ['New', 'Acknowledged', 'Assigned', 'In Progress', 'Resolved', 'Closed'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Complaint Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              const Text('Select new workflow status for this maintenance ticket:', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statuses.map((s) {
                  final isCurrent = ticket.status == s;
                  final color = _getStatusColor(s);
                  return ActionChip(
                    backgroundColor: isCurrent ? color : Colors.white,
                    side: BorderSide(color: color),
                    label: Text(
                      s,
                      style: TextStyle(
                        color: isCurrent ? Colors.white : color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    onPressed: isCurrent
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            setState(() => _isUpdatingStatus = true);
                            try {
                              await ref.read(apartmentProvider.notifier).updateStatus(widget.ticketId, s);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Status updated to $s')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Status update failed: $e'), backgroundColor: Colors.red),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isUpdatingStatus = false);
                            }
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showAddInternalNoteDialog() {
    _internalNoteController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.lock_outline, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('Private Staff Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Visible only to Association Committee & Admin. Hidden from resident.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _internalNoteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter internal maintenance or technician instructions...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () async {
                final text = _internalNoteController.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(apartmentProvider.notifier).addInternalNote(widget.ticketId, text);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Internal note recorded successfully.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Save Note', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showResolveDialog() {
    _resolutionNotesController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Mark as Resolved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter notes describing the maintenance work completed for this resident.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _resolutionNotesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Replaced faulty washer and tested pipe flow. No leaks found.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final notes = _resolutionNotesController.text.trim();
                Navigator.pop(ctx);
                try {
                  await ref.read(apartmentProvider.notifier).resolveComplaint(widget.ticketId, notes);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Complaint marked as Resolved!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to resolve: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Confirm Resolution', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showReopenDialog() {
    _reopenReasonController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reopen Complaint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please explain why this issue is not fully resolved. A clear reason is required.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reopenReasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Slight dripping still observed around the corner tiles.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () async {
                final reason = _reopenReasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a reason to reopen.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref.read(apartmentProvider.notifier).reopenComplaint(widget.ticketId, reason);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Complaint reopened. In-charge has been notified.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Reopen Ticket', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(apartmentProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userRole = user?['role']?.toString().toLowerCase() ?? 'resident';
    final isInCharge = userRole == 'association' || userRole == 'admin';

    final ticket = state.selectedTicket;

    if (state.isLoading && ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complaint Details')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complaint Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Complaint record not found or access restricted.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Complaints'),
              ),
            ],
          ),
        ),
      );
    }

    final statusColor = _getStatusColor(ticket.status);
    final isResolvedOrClosed = ['Resolved', 'Closed'].contains(ticket.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Ticket #${ticket.ticketId}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(apartmentProvider.notifier).loadTicketDetails(widget.ticketId),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status & Priority Header Card
                  _buildHeaderCard(ticket, statusColor, isInCharge),

                  const SizedBox(height: 14),

                  // In-Charge Management Actions Bar
                  if (isInCharge) _buildInChargeActionBar(ticket),

                  const SizedBox(height: 14),

                  // Status Progression Timeline Stepper
                  _buildStatusStepper(ticket),

                  const SizedBox(height: 14),

                  // Assigned Technician Section
                  if (ticket.assignedStaffName != null && ticket.assignedStaffName!.isNotEmpty)
                    _buildTechnicianCard(ticket),

                  const SizedBox(height: 14),

                  // Description & Uploaded Photos
                  _buildDescriptionCard(ticket),

                  const SizedBox(height: 14),

                  // Resolution Notes (if resolved)
                  if (ticket.resolutionNotes != null && ticket.resolutionNotes!.isNotEmpty)
                    _buildResolutionCard(ticket),

                  const SizedBox(height: 14),

                  // Private Internal Notes (Visible ONLY to in-charge / admin)
                  if (isInCharge && ticket.internalNotes.isNotEmpty)
                    _buildInternalNotesCard(ticket),

                  const SizedBox(height: 14),

                  // Resident Reopen Button
                  if (!isInCharge && isResolvedOrClosed)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepOrange,
                          side: const BorderSide(color: Colors.deepOrange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.replay_outlined, size: 18),
                        label: const Text('Issue Not Resolved? Reopen Complaint', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _showReopenDialog,
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Discussion / Messages Thread
                  _buildMessagesThread(ticket, user),
                ],
              ),
            ),
          ),

          // Message reply input bar
          _buildReplyInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(SocietyTicketModel ticket, Color statusColor, bool isInCharge) {
    final formattedDate = DateFormat('EEEE, d MMM yyyy • h:mm a').format(ticket.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Text(
                'Flat ${ticket.flatNumber} • ${ticket.block.isNotEmpty ? ticket.block : "Block A"}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ticket.subject,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 4),
          Text(formattedDate, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(ticket.category, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.purple.shade50,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              ),
              Chip(
                label: Text('Priority: ${ticket.priority}', style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.amber.shade50,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              ),
              if (ticket.isOverdue)
                Chip(
                  label: const Text('Ageing: >3 Days', style: TextStyle(fontSize: 11, color: Colors.red)),
                  backgroundColor: Colors.red.shade50,
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInChargeActionBar(SocietyTicketModel ticket) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.admin_panel_settings, color: Color(0xFF4338CA), size: 18),
              SizedBox(width: 6),
              Text('In-Charge Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4338CA),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.edit_note, size: 16, color: Colors.white),
                  label: const Text('Update Status', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: _isUpdatingStatus ? null : () => _showUpdateStatusSheet(ticket),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.lock_outline, size: 16, color: Colors.amber),
                  label: const Text('Internal Note', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  onPressed: _showAddInternalNoteDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.done_all, size: 16, color: Colors.white),
                  label: const Text('Resolve', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: _showResolveDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(SocietyTicketModel ticket) {
    final statuses = ['New', 'Acknowledged', 'Assigned', 'In Progress', 'Resolved', 'Closed'];
    final currentIndex = statuses.indexOf(ticket.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Complaint Tracking Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 14),

          // Stepper bar
          Row(
            children: List.generate(statuses.length * 2 - 1, (i) {
              if (i % 2 == 1) {
                // connector line
                final stepIdx = (i - 1) ~/ 2;
                final isDone = currentIndex > stepIdx;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isDone ? Colors.green : Colors.grey.shade300,
                  ),
                );
              } else {
                // circle
                final stepIdx = i ~/ 2;
                final isCurrent = currentIndex == stepIdx;
                final isDone = currentIndex > stepIdx;
                final color = isCurrent ? AppTheme.primaryColor : (isDone ? Colors.green : Colors.grey.shade300);

                return Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : Text(
                            '${stepIdx + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Submitted', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              Text('Progressing', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              Text('Resolved', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),

          // Status history details
          if (ticket.statusHistory.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Status Updates History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            const SizedBox(height: 8),
            ...ticket.statusHistory.reversed.take(4).map((h) {
              final timeStr = DateFormat('d MMM, h:mm a').format(h.timestamp);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${h.status}: ${h.reason.isNotEmpty ? h.reason : "Updated by ${h.changedByName}"} ($timeStr)',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textPrimaryColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(SocietyTicketModel ticket) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: const Icon(Icons.engineering_outlined, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assigned Maintenance Staff', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                Text(
                  ticket.assignedStaffName ?? 'Maintenance Technician',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          if (ticket.assignedStaffPhone != null && ticket.assignedStaffPhone!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
              onPressed: () async {
                final uri = Uri.parse('tel:${ticket.assignedStaffPhone}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(SocietyTicketModel ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Complaint Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(height: 8),
          Text(
            ticket.description.isNotEmpty ? ticket.description : 'No additional description provided.',
            style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimaryColor),
          ),
          if (ticket.attachments.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Uploaded Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ticket.attachments.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final url = ticket.attachments[i];
                  return GestureDetector(
                    onTap: () => _openImageDialog(url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 28, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResolutionCard(SocietyTicketModel ticket) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
              SizedBox(width: 6),
              Text('Resolution Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ticket.resolutionNotes ?? '',
            style: TextStyle(fontSize: 12.5, color: Colors.green.shade900, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalNotesCard(SocietyTicketModel ticket) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lock, color: Colors.amber, size: 16),
              SizedBox(width: 6),
              Text('Confidential Staff Notes (Hidden from Resident)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
            ],
          ),
          const SizedBox(height: 8),
          ...ticket.internalNotes.map((n) {
            final dateStr = DateFormat('d MMM, h:mm a').format(n.createdAt);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '• ${n.text} (${n.addedByName}, $dateStr)',
                style: const TextStyle(fontSize: 12, color: Colors.brown),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMessagesThread(SocietyTicketModel ticket, Map<String, dynamic>? currentUser) {
    final currentUserId = currentUser?['id']?.toString() ?? currentUser?['userId']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discussion Thread', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                '${ticket.messages.length} messages',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
          const Divider(height: 20),
          if (ticket.messages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No messages yet. Post a reply below.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ticket.messages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final msg = ticket.messages[i];
                final isMe = msg.senderId == currentUserId;
                final timeStr = DateFormat('d MMM, h:mm a').format(msg.createdAt);

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isMe ? 'You' : msg.senderName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isMe ? Colors.white70 : AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.white24 : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                msg.senderRole.toUpperCase(),
                                style: TextStyle(fontSize: 9, color: isMe ? Colors.white : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: isMe ? Colors.white : AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            timeStr,
                            style: TextStyle(fontSize: 9.5, color: isMe ? Colors.white60 : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReplyInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Type your message or update here...',
                  hintStyle: const TextStyle(fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppTheme.primaryColor,
              shape: const CircleBorder(),
              child: IconButton(
                icon: _isSendingReply
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _isSendingReply ? null : _handleSendReply,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImageDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
