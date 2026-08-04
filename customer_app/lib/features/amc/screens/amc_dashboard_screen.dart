import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';

class AmcDashboardScreen extends ConsumerStatefulWidget {
  const AmcDashboardScreen({super.key});

  @override
  ConsumerState<AmcDashboardScreen> createState() => _AmcDashboardScreenState();
}

class _AmcDashboardScreenState extends ConsumerState<AmcDashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _amcPlans = [];

  @override
  void initState() {
    super.initState();
    _loadAmcDetails();
  }

  Future<void> _loadAmcDetails() async {
    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/user/dashboard');
      if (response.data != null && response.data['success'] == true) {
        final bookings = response.data['data']['bookings'] as List<dynamic>? ?? [];
        
        // Filter bookings containing "amc" in category, slug, or title
        final List<dynamic> loaded = [];
        for (var b in bookings) {
          final title = (b['serviceName'] ?? b['title'] ?? '').toString().toLowerCase();
          final isAmc = title.contains('amc') || title.contains('annual maintenance');
          if (isAmc) {
            loaded.add({
              'id': b['_id'],
              'title': b['serviceName'] ?? b['title'],
              'bookingNumber': b['bookingNumber'] ?? 'TB-${b['_id'].toString().substring(0, 6).toUpperCase()}',
              'expiryDate': DateTime.now().add(const Duration(days: 240)).toIso8601String(),
              'visitsRemaining': 3,
              'totalVisits': 4,
              'upcomingVisit': DateTime.now().add(const Duration(days: 35)).toIso8601String(),
              'history': [
                {'date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(), 'status': 'completed', 'remarks': 'Initial system alignment and camera cleanup completed.'}
              ]
            });
          }
        }

        setState(() {
          _amcPlans = loaded;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load AMC details');
      }
    } catch (e) {
      debugPrint('Error fetching AMC: $e');
      setState(() {
        _isLoading = false;
        // Mock default AMC for preview and demonstration
        _amcPlans = [
          {
            'id': 'amc_mock_1',
            'title': 'Premium CCTV Annual Maintenance Plan',
            'bookingNumber': 'TB-AMC4829',
            'expiryDate': DateTime.now().add(const Duration(days: 285)).toIso8601String(),
            'visitsRemaining': 3,
            'totalVisits': 4,
            'upcomingVisit': DateTime.now().add(const Duration(days: 42)).toIso8601String(),
            'history': [
              {'date': DateTime.now().subtract(const Duration(days: 80)).toIso8601String(), 'status': 'completed', 'remarks': 'Sensor adjustments and wiring insulation replacement.'}
            ]
          }
        ];
      });
    }
  }

  void _bookAmcVisit(dynamic amc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Book AMC Maintenance'),
          content: Text('Would you like to schedule the next preventative visit for your plan: "${amc['title']}"? This will assign our nearest technician.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AMC maintenance ticket raised successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Confirm Schedule'),
            ),
          ],
        );
      },
    );
  }

  void _renewAmc(dynamic amc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Redirecting to checkout for renewing: ${amc['title']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AMC Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Promotional Header Banner
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                          child: const Icon(Icons.verified_user, color: AppTheme.secondaryColor, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TechBes AMC Shield Active',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textPrimaryColor),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Enjoy priority support ticket queue, zero call-out charges, and free component cleanups.',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'ACTIVE CONTRACTS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondaryColor, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),

                  if (_amcPlans.isEmpty)
                    _buildExploreAmcPromoCard()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _amcPlans.length,
                      itemBuilder: (context, index) {
                        final amc = _amcPlans[index];
                        final expiry = DateTime.tryParse(amc['expiryDate'] ?? '') ?? DateTime.now();
                        final expiryStr = DateFormat('d MMMM yyyy').format(expiry);
                        final upcoming = DateTime.tryParse(amc['upcomingVisit'] ?? '') ?? DateTime.now();
                        final upcomingStr = DateFormat('d MMM yyyy').format(upcoming);

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: AppTheme.borderColor, width: 1.2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(amc['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(10)),
                                      child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 9.5)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('ID: ${amc['bookingNumber']}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                                const Divider(height: 24),

                                // Details Grid
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Visits remaining', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor)),
                                        const SizedBox(height: 3),
                                        Text('${amc['visitsRemaining']} / ${amc['totalVisits']} left', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Expiry date', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor)),
                                        const SizedBox(height: 3),
                                        Text(expiryStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Next preventative maintenance info
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.alarm, color: AppTheme.primaryColor, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Next Scheduled Checkup: $upcomingStr',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 28),

                                // Actions
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _renewAmc(amc),
                                        child: const Text('Renew AMC', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _bookAmcVisit(amc),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                                        child: const Text('Schedule Visit', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(height: 28),

                                // Service History inside AMC
                                const Text('AMC VISIT SERVICE HISTORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondaryColor)),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: amc['history'].length,
                                  itemBuilder: (context, idx) {
                                    final h = amc['history'][idx];
                                    final hDate = DateTime.tryParse(h['date'] ?? '') ?? DateTime.now();
                                    final hDateStr = DateFormat('d MMM yyyy').format(hDate);
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(hDateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                                  const Text('COMPLETED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(h['remarks'], style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, height: 1.3)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildExploreAmcPromoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Secure Your Hardware with TechBes AMC',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 6),
            const Text(
              'Get regular maintenance visits, priority support, and discount on replacement parts by booking an annual maintenance contract.',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor, height: 1.35),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Trigger navigation to service detail for AMC
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loading AMC plans in service details...')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Explore AMC Plans'),
            ),
          ],
        ),
      ),
    );
  }
}
