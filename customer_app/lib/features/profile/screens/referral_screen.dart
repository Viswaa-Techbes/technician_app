import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  bool _isLoading = true;
  String _referralCode = 'TB-REF9182';
  double _referralEarnings = 500;
  int _referralsCount = 2;
  String _loyaltyLevel = 'Silver';
  int _pointsToNextLevel = 150;

  final List<dynamic> _referralHistory = [
    {'name': 'Amit Patel', 'status': 'completed', 'bonus': '₹250'},
    {'name': 'Rakesh Sharma', 'status': 'completed', 'bonus': '₹250'},
  ];

  @override
  void initState() {
    super.initState();
    _loadReferralInfo();
  }

  Future<void> _loadReferralInfo() async {
    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/user/dashboard');
      if (response.data != null && response.data['success'] == true) {
        final profile = response.data['data']['profile'] ?? {};
        final metrics = response.data['data']['metrics'] ?? {};

        // Derive sequential unique code from customerId
        final cusId = profile['customerId'] ?? '';
        final suffix = cusId.isNotEmpty ? cusId.toString().split('-').last : '9182';
        
        // Calculate loyalty tier based on payments volume
        final totalPaid = (metrics['totalPaid'] ?? 0).toDouble();
        String tier = 'Silver';
        int remaining = 150;
        if (totalPaid >= 30000) {
          tier = 'Platinum';
          remaining = 0;
        } else if (totalPaid >= 15000) {
          tier = 'Gold';
          remaining = (30000 - totalPaid).round();
        } else {
          remaining = (15000 - totalPaid).round();
        }

        setState(() {
          _referralCode = 'TB-REF$suffix';
          _loyaltyLevel = tier;
          _pointsToNextLevel = remaining;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load referral details');
      }
    } catch (e) {
      debugPrint('Error loading referrals: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referrals & Rewards'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Referral invite card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(Icons.card_giftcard, size: 48, color: AppTheme.secondaryColor),
                          const SizedBox(height: 12),
                          const Text(
                            'Refer Friends, Earn Wallet Credits',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Get Flat ₹250 credited to your TechBes wallet when your friend completes their first service booking check.',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          const Divider(height: 30),

                          // Code Display Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _referralCode,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5, color: AppTheme.textPrimaryColor),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Referral invite link copied to clipboard!')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Loyalty tier card (Silver, Gold, Platinum)
                  Card(
                    elevation: 0,
                    color: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('LOYALTY TIER STATUS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_loyaltyLevel Member',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                                  ),
                                ],
                              ),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white.withOpacity(0.12),
                                child: Icon(
                                  Icons.workspace_premium,
                                  color: _loyaltyLevel == 'Platinum'
                                      ? Colors.tealAccent
                                      : _loyaltyLevel == 'Gold'
                                          ? Colors.amberAccent
                                          : Colors.blueGrey.shade100,
                                  size: 24,
                                ),
                              )
                            ],
                          ),
                          const Divider(height: 24, color: Colors.white24),
                          
                          // Linear progress indicator
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _loyaltyLevel == 'Platinum' ? 1.0 : (_loyaltyLevel == 'Gold' ? 0.75 : 0.40),
                              backgroundColor: Colors.white12,
                              color: AppTheme.secondaryColor,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_loyaltyLevel != 'Platinum')
                            Text(
                              'Spend ₹$_pointsToNextLevel more to unlock next premium rewards tier status.',
                              style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                            )
                          else
                            const Text(
                              'You are at our highest loyalty status tier! Enjoy 24/7 service priority queue.',
                              style: TextStyle(color: Colors.white70, fontSize: 10.5),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Referral History and stats
                  const Text(
                    'REFERRAL LOGS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondaryColor, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _referralHistory.length,
                    itemBuilder: (context, index) {
                      final h = _referralHistory[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            radius: 16,
                            child: Icon(Icons.person, size: 16),
                          ),
                          title: Text(h['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: const Text('First Booking Complete', style: TextStyle(fontSize: 11)),
                          trailing: Text(
                            '+${h['bonus']}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.green),
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
    );
  }
}
