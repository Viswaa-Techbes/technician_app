import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/apartment_provider.dart';
import '../../../models/society_ticket_model.dart';

class ApartmentDashboardScreen extends ConsumerStatefulWidget {
  const ApartmentDashboardScreen({super.key});

  @override
  ConsumerState<ApartmentDashboardScreen> createState() => _ApartmentDashboardScreenState();
}

class _ApartmentDashboardScreenState extends ConsumerState<ApartmentDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(apartmentProvider.notifier).refreshAll());
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Emergency':
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange.shade800;
      case 'Medium':
        return Colors.amber.shade700;
      case 'Low':
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(apartmentProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userRole = user?['role']?.toString().toLowerCase() ?? 'resident';
    final isInCharge = userRole == 'association' || userRole == 'admin';

    final apt = state.profileData?.apartment;
    final res = state.profileData?.resident;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isInCharge ? 'Apartment In-Charge Hub' : 'My Apartment & Complaints',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(apartmentProvider.notifier).refreshAll(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Register Complaint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => context.push('/apartment/register-complaint'),
      ),
      body: state.isLoading && state.profileData == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: () => ref.read(apartmentProvider.notifier).refreshAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // In-Charge Banner if association user
                    if (isInCharge)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4338CA).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Apartment In-Charge Mode',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Managing complaints for ${apt?.name ?? "Assigned Society"}. Tap any complaint to update status or post internal notes.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // My Apartment Card
                    _buildApartmentDetailsCard(apt, res, isInCharge),

                    const SizedBox(height: 16),

                    // Quick Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            icon: Icons.add_circle_outline,
                            label: 'Register Complaint',
                            subtitle: 'Report maintenance issue',
                            color: AppTheme.primaryColor,
                            onTap: () => context.push('/apartment/register-complaint'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionButton(
                            icon: Icons.contact_phone_outlined,
                            label: 'Society Committee',
                            subtitle: '${apt?.associationUsers.length ?? 0} in-charge members',
                            color: const Color(0xFF0D9488),
                            onTap: () => _showCommitteeModal(context, apt),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Complaints Header & Search
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isInCharge ? 'Society Complaints Queue' : 'My Complaints History',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${state.filteredTickets.length} Total',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Search input
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by ticket ID, flat, or subject...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(apartmentProvider.notifier).setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {});
                        ref.read(apartmentProvider.notifier).setSearchQuery(val);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Filter Chips (All, Active, Resolved, Closed)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', state.statusFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('Active', state.statusFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('New', state.statusFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('In Progress', state.statusFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('Resolved', state.statusFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('Closed', state.statusFilter),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Complaints List
                    if (state.filteredTickets.isEmpty)
                      _buildEmptyState(isInCharge)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.filteredTickets.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ticket = state.filteredTickets[index];
                          return _buildTicketCard(context, ticket, isInCharge);
                        },
                      ),

                    const SizedBox(height: 80), // Fab padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, String current) {
    final isSelected = current.toLowerCase() == label.toLowerCase();
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
      ),
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
      onSelected: (_) {
        ref.read(apartmentProvider.notifier).setFilter(label);
      },
    );
  }

  Widget _buildApartmentDetailsCard(dynamic apt, dynamic res, bool isInCharge) {
    final aptName = apt?.name ?? 'TechBes Demo Residency';
    final address = apt?.address ?? 'Plot 101, Electronic City Phase 1, Bangalore';
    final flat = res?.flatNumber.isNotEmpty == true ? res.flatNumber : (isInCharge ? 'Committee Desk' : 'A-101');
    final block = res?.block.isNotEmpty == true ? res.block : (isInCharge ? 'Administration' : 'Block A');
    final residentType = res?.residentType ?? (isInCharge ? 'In-Charge' : 'Owner');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.apartment_rounded, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aptName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem(Icons.door_front_door_outlined, 'Flat Number', flat),
              _buildDetailItem(Icons.business_outlined, 'Block/Tower', block),
              _buildDetailItem(
                Icons.verified_user_outlined,
                'Resident Type',
                residentType.toString().toUpperCase(),
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {bool highlight = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondaryColor),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: highlight ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, SocietyTicketModel ticket, bool isInCharge) {
    final statusColor = _getStatusColor(ticket.status);
    final priorityColor = _getPriorityColor(ticket.priority);
    final formattedDate = DateFormat('dd MMM yyyy, h:mm a').format(ticket.createdAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          context.push('/apartment/complaints/${ticket.id}');
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ticket.isOverdue ? Colors.red.shade300 : Colors.grey.shade200,
              width: ticket.isOverdue ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Ticket ID, Date, Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${ticket.ticketId}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      if (ticket.isOverdue) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Text(
                            'OVERDUE',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title / Subject
              Text(
                ticket.subject,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Description snippet
              if (ticket.description.isNotEmpty)
                Text(
                  ticket.description,
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 10),

              // Flat, Category, Priority chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Flat ${ticket.flatNumber}',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.category,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.purple.shade800),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.priority,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: priorityColor),
                    ),
                  ),
                  if (ticket.attachments.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_outlined, size: 11, color: Colors.green.shade800),
                          const SizedBox(width: 3),
                          Text(
                            '${ticket.attachments.length} Photo',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const Divider(height: 18),

              // Bottom row: submission date, messages count, arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                  ),
                  Row(
                    children: [
                      if (ticket.messages.isNotEmpty) ...[
                        Icon(Icons.chat_bubble_outline, size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${ticket.messages.length}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 10),
                      ],
                      const Text(
                        'View & Track',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right, size: 16, color: AppTheme.primaryColor),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isInCharge) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_turned_in_outlined, size: 36, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 14),
          Text(
            isInCharge ? 'No complaints in this queue' : 'No complaints registered yet',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 6),
          Text(
            isInCharge
                ? 'All maintenance tickets for this apartment community are resolved.'
                : 'Need maintenance help for plumbing, electricity, lifts, or security? Register your first complaint now.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  void _showCommitteeModal(BuildContext context, dynamic apt) {
    final users = apt?.associationUsers ?? [];
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Apartment Committee Contacts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No committee members assigned to this society yet.'),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (ctx, i) {
                    final u = users[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          u.name.isNotEmpty ? u.name[0].toUpperCase() : 'C',
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(u.mobileNumber.isNotEmpty ? u.mobileNumber : u.email, style: const TextStyle(fontSize: 12)),
                      trailing: u.mobileNumber.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                              onPressed: () async {
                                final uri = Uri.parse('tel:${u.mobileNumber}');
                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                              },
                            )
                          : null,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
