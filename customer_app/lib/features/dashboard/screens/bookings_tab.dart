import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

class BookingsTab extends ConsumerStatefulWidget {
  const BookingsTab({super.key});

  @override
  ConsumerState<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<BookingsTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _bookings = [];
  Map<String, dynamic> _profile = {};

  // Review state
  dynamic _selectedBookingForReview;
  int _reviewRating = 5;
  final _reviewCommentController = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    _reviewCommentController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/user/dashboard');
      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _bookings = response.data['data']['bookings'] ?? [];
          _profile = response.data['data']['profile'] ?? {};
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      setState(() {
        _error = 'Failed to load bookings.';
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
        const SnackBar(content: Text('No technician assigned to this job')),
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
          const SnackBar(content: Text('Thank you! Review submitted successfully.')),
        );
        setState(() {
          _selectedBookingForReview = null;
          _reviewCommentController.clear();
          _reviewRating = 5;
        });
        _loadBookings();
      }
    } catch (e) {
      debugPrint('Review error: $e');
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Rate & Review service', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Technician: ${booking['assignedTechnician']?['name'] ?? 'Assigned Partner'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          color: starVal <= _reviewRating ? Colors.amber.shade600 : Colors.blueGrey.shade200,
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
                      hintText: 'Share your experience with our services...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
                  child: _isSubmittingReview
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadBookings, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final upcomingList = _bookings.where((b) {
      final status = (b['status'] ?? b['bookingStatus'] ?? 'pending').toString().toLowerCase();
      return status == 'pending' || status == 'dispatched' || status == 'in_progress' || status == 'active';
    }).toList();

    final completedList = _bookings.where((b) {
      final status = (b['status'] ?? b['bookingStatus'] ?? 'pending').toString().toLowerCase();
      return status == 'completed';
    }).toList();

    final cancelledList = _bookings.where((b) {
      final status = (b['status'] ?? b['bookingStatus'] ?? 'pending').toString().toLowerCase();
      return status == 'cancelled';
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _subTabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _subTabController,
        children: [
          _buildBookingsList(upcomingList, true),
          _buildBookingsList(completedList, false),
          _buildBookingsList(cancelledList, false),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<dynamic> list, bool activeTrackingAllowed) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 48, color: Colors.blueGrey.shade200),
              const SizedBox(height: 16),
              const Text(
                'No bookings found',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 6),
              const Text(
                'Configure a service and choose checkout to book schedule.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final b = list[index];
          final id = b['_id'];
          final status = b['status'] ?? b['bookingStatus'] ?? 'pending';
          final paymentStatus = b['paymentStatus'] ?? 'pending';
          final date = b['bookingDate'] ?? b['scheduledDate'] ?? 'Date pending';
          final time = b['timeSlot'] ?? b['scheduledTime'] ?? '';
          final technician = b['assignedTechnician']?['name'] ?? 'Unassigned';
          final isCompleted = status == 'completed';
          final isDispatched = status == 'dispatched' || status == 'in_progress' || status == 'active';

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          b['serviceName'] ?? b['title'] ?? 'CCTV Service',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimaryColor),
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
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                  ),
                  const Divider(height: 24),
                  _buildDetailLine('Status', _statusBadge(status)),
                  const SizedBox(height: 8),
                  _buildDetailLine('Payment Status', Text(
                    paymentStatus.toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: paymentStatus == 'paid' ? const Color(0xFF10B981) : Colors.amber.shade700,
                    ),
                  )),
                  const SizedBox(height: 8),
                  _buildDetailLine('Scheduled Time', Text('$date $time', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  _buildDetailLine('Assigned Partner', Text(technician, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  
                  if (activeTrackingAllowed && (isDispatched || isCompleted)) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        if (isDispatched)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/tracking/$id'),
                              icon: const Icon(Icons.map, size: 16),
                              label: const Text('Track Technician', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        if (isCompleted) ...[
                          if (b['rating'] != null)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'You Rated: ${b['rating']} / 5',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (b['assignedTechnician'] != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openReviewDialog(b),
                                icon: const Icon(Icons.star_border, size: 16),
                                label: const Text('Rate & Review', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailLine(String label, Widget value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
        value,
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bg = Colors.blueGrey.shade50;
    Color fg = Colors.blueGrey.shade600;

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
}
