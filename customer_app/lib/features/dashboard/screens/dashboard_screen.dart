import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_config.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  // Dashboard Data State
  Map<String, dynamic> _profile = {};
  List<dynamic> _metrics = [];
  List<dynamic> _bookings = [];
  List<dynamic> _addresses = [];
  List<dynamic> _payments = [];
  List<dynamic> _serviceReports = [];

  // Review submission state
  dynamic _selectedBookingForReview;
  int _reviewRating = 5;
  final _reviewCommentController = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewCommentController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/user/dashboard');

      if (response.data != null && response.data['success'] == true) {
        final raw = response.data['data'];
        setState(() {
          _profile = raw['profile'] ?? {};
          
          final upcoming = raw['metrics']?.containsKey('upcomingServices') == true ? raw['metrics']['upcomingServices'] : 0;
          final history = raw['metrics']?.containsKey('orderHistory') == true ? raw['metrics']['orderHistory'] : 0;
          final savedAddr = raw['metrics']?.containsKey('savedAddresses') == true ? raw['metrics']['savedAddresses'] : 0;
          final payCount = raw['metrics']?.containsKey('payments') == true ? raw['metrics']['payments'] : 0;

          _metrics = [
            {'title': 'Upcoming services', 'value': '$upcoming', 'icon': Icons.calendar_today, 'color': const Color(0xFF10B981)},
            {'title': 'Order history', 'value': '$history', 'icon': Icons.history, 'color': Colors.blue},
            {'title': 'Saved addresses', 'value': '$savedAddr', 'icon': Icons.map, 'color': const Color(0xFF10B981)},
            {'title': 'Payments', 'value': '$payCount', 'icon': Icons.payment, 'color': Colors.blue},
          ];

          _bookings = raw['bookings'] ?? [];
          _addresses = raw['addresses'] ?? [];
          _payments = raw['payments'] ?? [];
          _serviceReports = raw['serviceReports'] ?? [];
          
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      setState(() {
        _errorMessage = 'Failed to load dashboard data. Ensure you are connected to the network.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_selectedBookingForReview == null) return;
    
    final techId = _selectedBookingForReview['assignedTechnician']?['_id'] ?? 
                   _selectedBookingForReview['assignedTechnician']?['id'] ?? 
                   _selectedBookingForReview['assignedTechnician'];

    if (techId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot review: No technician assigned to this job')),
      );
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.post('/reviews', data: {
        'rating': _reviewRating,
        'comment': _reviewCommentController.text.trim(),
        'technicianId': techId,
        'jobId': _selectedBookingForReview['_id'],
        'clientName': _profile['name'] ?? 'Customer',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        setState(() {
          _selectedBookingForReview = null;
          _reviewCommentController.clear();
          _reviewRating = 5;
        });
        _loadDashboardData(); // reload
      }
    } catch (e) {
      debugPrint('Failed to submit review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmittingReview = false;
      });
    }
  }

  void _openReviewDialog(dynamic booking) {
    setState(() {
      _selectedBookingForReview = booking;
      _reviewRating = 5;
      _reviewCommentController.clear();
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Rate & Review Service', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Technician: ${booking['assignedTechnician']?['name'] ?? 'Assigned Professional'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Service: ${booking['serviceName'] ?? booking['title']}',
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Text('Your Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          color: starVal <= _reviewRating ? Colors.amber.shade600 : Colors.blueGrey.shade300,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            _reviewRating = starVal;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reviewCommentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience with our service...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _selectedBookingForReview = null);
                  },
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryColor)),
                ),
                ElevatedButton(
                  onPressed: _isSubmittingReview 
                      ? null 
                      : () async {
                          setDialogState(() => _isSubmittingReview = true);
                          await _submitReview();
                          setDialogState(() => _isSubmittingReview = false);
                          if (mounted && _selectedBookingForReview == null) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isSubmittingReview
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Review'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openPDFReport(String? pdfUrl) async {
    if (pdfUrl == null || pdfUrl.isEmpty) return;
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF report link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadDashboardData, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          tabs: const [
            Tab(text: 'Bookings'),
            Tab(text: 'Addresses'),
            Tab(text: 'Payments'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Profile Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: _profile['profilePhoto'] != null ? NetworkImage(_profile['profilePhoto']) : null,
                    child: _profile['profilePhoto'] == null 
                        ? const Icon(Icons.person, color: Colors.white, size: 28) 
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile['name'] ?? user?['name'] ?? 'Customer',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _profile['email'] ?? user?['email'] ?? 'Inquiry email',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        if (_profile['phone'] != null || _profile['mobileNumber'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _profile['phone'] ?? _profile['mobileNumber'] ?? '',
                              style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Scrollable content area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsTab(),
                _buildAddressesTab(),
                _buildPaymentsTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    if (_bookings.isEmpty) {
      return _buildEmptyState('No bookings found', 'You have not scheduled any service tasks yet.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final b = _bookings[index];
        final id = b['_id'];
        final status = b['status'] ?? b['bookingStatus'] ?? 'pending';
        final paymentStatus = b['paymentStatus'] ?? 'pending';
        final date = b['bookingDate'] ?? b['scheduledDate'] ?? 'Date pending';
        final time = b['timeSlot'] ?? b['scheduledTime'] ?? '';
        final technician = b['assignedTechnician']?['name'] ?? 'Unassigned';
        final isCompleted = status == 'completed';
        final isActive = status == 'dispatched' || status == 'in_progress' || status == 'active';
        
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b['serviceName'] ?? b['title'] ?? 'CCTV Service',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textPrimaryColor),
                      ),
                    ),
                    Text(
                      '₹${(b['amount'] ?? b['price'] ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${b['bookingNumber'] ?? id}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor),
                ),
                const Divider(height: 20),
                
                // Details Grid
                _buildDetailRow('Status', _statusBadge(status)),
                const SizedBox(height: 6),
                _buildDetailRow('Payment Status', Text(
                  paymentStatus.toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: paymentStatus == 'paid' ? const Color(0xFF10B981) : Colors.amber.shade700,
                  ),
                )),
                const SizedBox(height: 6),
                _buildDetailRow('Scheduled', Text('$date $time', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                _buildDetailRow('Technician', Text(technician, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),

                if (isActive || isCompleted) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      if (isActive)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.push('/tracking/$id');
                            },
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('Track Tech', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      if (isCompleted) ...[
                        if (b['rating'] != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'You rated: ${b['rating']} / 5',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (b['assignedTechnician'] != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openReviewDialog(b),
                              icon: const Icon(Icons.star_outline, size: 16),
                              label: const Text('Rate & Review', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressesTab() {
    if (_addresses.isEmpty) {
      return _buildEmptyState('No saved addresses', 'Add addresses at checkout to save them here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final addr = _addresses[index];
        final formatted = addr['formattedAddress'] ?? 
            [
              addr['address'] ?? addr['addressLine1'],
              addr['addressLine2'],
              addr['city'],
              addr['state'],
              addr['pincode']
            ].where((s) => s != null && s.toString().isNotEmpty).join(', ');

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      addr['label'] ?? 'Address',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textPrimaryColor),
                    ),
                    if (addr['isDefault'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Default', style: TextStyle(color: Color(0xFF065F46), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${addr['name']} — ${addr['mobile']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.textPrimaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  formatted,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, height: 1.4),
                ),
                if (addr['latitude'] != null && addr['longitude'] != null) ...[
                  const Divider(height: 20),
                  TextButton.icon(
                    onPressed: () async {
                      final url = Uri.parse('https://maps.google.com/?q=${addr['latitude']},${addr['longitude']}');
                      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.map, size: 14, color: Colors.blue),
                    label: const Text('View on Google Maps', style: TextStyle(fontSize: 11.5, color: Colors.blue, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return _buildEmptyState('No payments found', 'Your advance booking transactions records will display here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final p = _payments[index];
        final amount = (p['amount'] ?? 0) / 100;
        final date = p['createdAt'] != null ? DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(p['createdAt'])) : '-';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: ListTile(
            title: Text(
              p['razorpayPaymentId'] ?? p['_id'] ?? 'Payment ID Pending',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
            ),
            subtitle: Text(date, style: const TextStyle(fontSize: 11.5)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(
                  p['status']?.toString().toUpperCase() ?? 'SUCCESS',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    if (_serviceReports.isEmpty) {
      return _buildEmptyState('No service reports', 'After service completion, detailed PDF observation worksheets will list here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _serviceReports.length,
      itemBuilder: (context, index) {
        final rep = _serviceReports[index];
        final dateStr = rep['completionDate'] != null ? DateFormat('d MMM yyyy').format(DateTime.parse(rep['completionDate'])) : '';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Booking #${rep['bookingNumber'] ?? rep['jobId']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Technician: ${rep['technician'] ?? 'Assigned partner'}',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.push('/reports/${rep['jobId']}');
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                        child: const Text('View Report', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    if (rep['pdfReport'] != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openPDFReport(rep['pdfReport']),
                          icon: const Icon(Icons.download, size: 14),
                          label: const Text('Download PDF', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 10)),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, Widget value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
        value,
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bg = Colors.blueGrey.shade100;
    Color fg = Colors.blueGrey.shade700;

    switch (status.toLowerCase()) {
      case 'pending':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      case 'dispatched':
      case 'active':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        break;
      case 'in_progress':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        break;
      case 'completed':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.blueGrey.shade300),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper extension on Iterable
extension Filters<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) {
    final List<T> result = [];
    for (var element in this) {
      if (test(element)) result.add(element);
    }
    return result;
  }
}
