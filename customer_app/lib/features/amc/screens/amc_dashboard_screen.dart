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
      final response = await client.get('/api/v2/amc/customer/contracts');
      if (response.data != null && response.data['success'] == true) {
        final contracts = response.data['data'] as List<dynamic>? ?? [];
        
        final List<dynamic> loaded = [];
        for (var c in contracts) {
          String? upcomingVisitDate;
          final visits = c['visits'] as List<dynamic>? ?? [];
          for (var v in visits) {
            if (v['status'] == 'Scheduled') {
              upcomingVisitDate = v['visitDate'];
              break;
            }
          }

          final List<dynamic> history = [];
          for (var v in visits) {
            if (v['status'] == 'Completed') {
              history.add({
                'date': v['completionDetails']?['completedAt'] ?? v['visitDate'],
                'status': 'completed',
                'remarks': v['completionDetails']?['notes'] ?? v['remarks'] ?? 'Maintenance visit completed.'
              });
            }
          }

          loaded.add({
            'id': c['_id'],
            'title': '${c['amcPlan']} Annual Maintenance Shield',
            'bookingNumber': c['contractId'],
            'expiryDate': c['expiryDate'],
            'visitsRemaining': c['remainingVisits'],
            'totalVisits': c['totalVisits'],
            'upcomingVisit': upcomingVisitDate ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
            'history': history,
            'assignedEngineer': c['assignedEngineer'],
          });
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
        _amcPlans = [];
      });
    }
  }

  void _bookAmcVisit(dynamic amc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Early Checkup Visit'),
          content: const Text('Would you like to schedule an early checkup visit for tomorrow? This will assign your dedicated technician.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
                  final client = ref.read(dioClientProvider);
                  final response = await client.post(
                    '/api/v2/amc/contracts/${amc['id']}/schedule',
                    data: {'visitDate': tomorrow, 'remarks': 'Requested early checkup visit via mobile app'},
                  );
                  if (response.data != null && response.data['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Early visit scheduled successfully!'), backgroundColor: Colors.green),
                    );
                    _loadAmcDetails();
                  } else {
                    throw Exception(response.data?['message'] ?? 'Failed to schedule');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _renewAmc(dynamic amc) async {
    try {
      final client = ref.read(dioClientProvider);
      final response = await client.post('/api/v2/amc/contracts/${amc['id']}/renew', data: {});
      if (response.data != null && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AMC Contract renewed successfully!'), backgroundColor: Colors.green),
        );
        _loadAmcDetails();
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to renew');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to renew: $e'), backgroundColor: Colors.red),
      );
    }
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
                                if (amc['assignedEngineer'] != null) ...[
                                  const SizedBox(height: 16),
                                  const Text('DEDICATED ENGINEER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondaryColor, letterSpacing: 0.5)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppTheme.primaryColor,
                                          child: Text(
                                            (amc['assignedEngineer']['name'] ?? 'T')[0].toString().toUpperCase(),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                amc['assignedEngineer']['name'] ?? 'Dedicated Engineer',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                amc['assignedEngineer']['mobileNumber'] ?? 'N/A',
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
