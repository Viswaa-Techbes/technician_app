import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';

class ServiceTimelineScreen extends ConsumerStatefulWidget {
  const ServiceTimelineScreen({super.key});

  @override
  ConsumerState<ServiceTimelineScreen> createState() => _ServiceTimelineScreenState();
}

class _ServiceTimelineScreenState extends ConsumerState<ServiceTimelineScreen> {
  bool _isLoading = true;
  List<dynamic> _timelineEvents = [];

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/user/dashboard');
      if (response.data != null && response.data['success'] == true) {
        final bookings = response.data['data']['bookings'] as List<dynamic>? ?? [];
        final List<dynamic> loaded = [];

        for (var b in bookings) {
          final status = (b['status'] ?? b['bookingStatus'] ?? 'pending').toString().toLowerCase();
          final isCompleted = status == 'completed';
          final title = b['serviceName'] ?? b['title'] ?? 'CCTV Service';
          final String type = title.toString().toLowerCase().contains('amc')
              ? 'AMC'
              : title.toString().toLowerCase().contains('repair')
                  ? 'Repair'
                  : title.toString().toLowerCase().contains('upgrade')
                      ? 'Upgrade'
                      : 'Installation';

          loaded.add({
            'id': b['_id'],
            'title': title,
            'bookingNumber': b['bookingNumber'] ?? 'TB-${b['_id'].toString().substring(0, 6).toUpperCase()}',
            'date': b['bookingDate'] ?? b['scheduledDate'] ?? DateTime.now().toIso8601String(),
            'technician': b['assignedTechnician']?['name'] ?? 'Unassigned Partner',
            'type': type,
            'status': status,
            'isCompleted': isCompleted,
            'price': (b['amount'] ?? b['price'] ?? 0).toDouble(),
          });
        }

        // Sort by date descending
        loaded.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

        setState(() {
          _timelineEvents = loaded;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load timeline dashboard events');
      }
    } catch (e) {
      debugPrint('Error loading timeline: $e');
      setState(() {
        _isLoading = false;
        // Mock fallback timeline events
        _timelineEvents = [
          {
            'id': 't_mock_1',
            'title': 'CCTV 4-Camera Installation',
            'bookingNumber': 'TB-82931',
            'date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
            'technician': 'Karthik Kumar',
            'type': 'Installation',
            'status': 'completed',
            'isCompleted': true,
            'price': 12499.0,
          },
          {
            'id': 't_mock_2',
            'title': 'Office Network Router Repair & Testing',
            'bookingNumber': 'TB-71289',
            'date': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
            'technician': 'Sanjay Sharma',
            'type': 'Repair',
            'status': 'completed',
            'isCompleted': true,
            'price': 1500.0,
          },
          {
            'id': 't_mock_3',
            'title': 'Annual Maintenance Contract Signup',
            'bookingNumber': 'TB-AMC4829',
            'date': DateTime.now().subtract(const Duration(days: 80)).toIso8601String(),
            'technician': 'Karthik Kumar',
            'type': 'AMC',
            'status': 'completed',
            'isCompleted': true,
            'price': 7999.0,
          }
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Service History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _timelineEvents.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _timelineEvents.length,
                  itemBuilder: (context, index) {
                    final ev = _timelineEvents[index];
                    final isFirst = index == 0;
                    final isLast = index == _timelineEvents.length - 1;
                    return _buildTimelineRow(ev, isFirst, isLast);
                  },
                ),
    );
  }

  Widget _buildTimelineRow(dynamic ev, bool isFirst, bool isLast) {
    final date = DateTime.tryParse(ev['date'] ?? '') ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy').format(date);
    
    // Choose colors based on type
    Color accentColor = AppTheme.primaryColor;
    IconData icon = Icons.build_circle;
    if (ev['type'] == 'Repair') {
      accentColor = Colors.orange;
      icon = Icons.handyman;
    } else if (ev['type'] == 'AMC') {
      accentColor = Colors.green;
      icon = Icons.shield;
    } else if (ev['type'] == 'Upgrade') {
      accentColor = Colors.purple;
      icon = Icons.trending_up;
    } else if (ev['type'] == 'Installation') {
      accentColor = Colors.blue;
      icon = Icons.videocam;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left timeline axis line & dot indicator
          Column(
            children: [
              Container(
                width: 3.5,
                height: 16,
                color: isFirst ? Colors.transparent : Colors.blueGrey.shade100,
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor.withOpacity(0.08),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              Expanded(
                child: Container(
                  width: 3.5,
                  color: isLast ? Colors.transparent : Colors.blueGrey.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Event Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Card(
                elevation: 0,
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: accentColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              ev['type'].toUpperCase(),
                              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5),
                            ),
                          ),
                          Text(dateStr, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ev['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimaryColor),
                      ),
                      const SizedBox(height: 2),
                      Text('Booking ID: #${ev['bookingNumber']}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                      const Divider(height: 20),

                      // Technicians info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blueGrey.shade50,
                            child: const Icon(Icons.person, size: 12, color: AppTheme.textSecondaryColor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tech: ${ev['technician']}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                            ),
                          ),
                          Text(
                            '₹${ev['price'].toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                      
                      // Status and Invoice link if completed
                      if (ev['isCompleted']) ...[
                        const Divider(height: 16),
                        GestureDetector(
                          onTap: () {
                            context.push('/invoice-center');
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('View GST Invoice', style: TextStyle(fontSize: 11.5, color: Colors.blue, fontWeight: FontWeight.bold)),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right, color: Colors.blue, size: 14),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline_outlined, size: 54, color: Colors.blueGrey.shade200),
            const SizedBox(height: 16),
            const Text(
              'Your Timeline is Empty',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your service timeline will trace installations, repairs, AMC logs, and audits once completed.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
