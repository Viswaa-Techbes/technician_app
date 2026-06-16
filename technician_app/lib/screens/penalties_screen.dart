import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class PenaltiesScreen extends ConsumerStatefulWidget {
  const PenaltiesScreen({super.key});

  @override
  ConsumerState<PenaltiesScreen> createState() => _PenaltiesScreenState();
}

class _PenaltiesScreenState extends ConsumerState<PenaltiesScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _profileFuture = ref.read(apiServiceProvider).getCurrentUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('MY PENALTIES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final profile = snapshot.data ?? {};
          final List<dynamic> penalties = profile['penalties'] ?? [];
          final penaltyPoints = profile['penaltyPoints'] ?? 0;

          // Compute summaries
          int pendingPenalties = 0;
          double totalAmount = 0;
          for (var p in penalties) {
            final status = p['status'] ?? 'pending';
            if (status == 'pending') {
              pendingPenalties++;
            }
            totalAmount += (p['amount'] as num?)?.toDouble() ?? 0.0;
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _profileFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Total Points",
                          penaltyPoints.toString(),
                          Icons.warning_amber_rounded,
                          const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          "Pending Fees",
                          pendingPenalties.toString(),
                          Icons.hourglass_empty_rounded,
                          const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    "Total Penalty Fees Amount",
                    "₹${totalAmount.toStringAsFixed(0)}",
                    Icons.payments_rounded,
                    const Color(0xFF1E3A8A),
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "PENALTY LOGS",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (penalties.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: Colors.white,
                      elevation: 0,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.verified_user_rounded, size: 48, color: Colors.green),
                              SizedBox(height: 16),
                              Text(
                                "No penalties applied. Keep up the good work!",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: penalties.length,
                      itemBuilder: (context, index) {
                        final p = penalties[index];
                        final rawDate = p['penaltyDate'];
                        final dateStr = rawDate != null 
                            ? DateTime.parse(rawDate.toString()).toLocal().toString().split(' ')[0] 
                            : 'Date TBD';
                        
                        final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
                        final reason = p['reason'] ?? 'Violation';
                        final status = p['status'] ?? 'pending';

                        // Extract job information if populated
                        final jobObj = p['jobId'];
                        String bookingNum = '—';
                        String customerName = '—';
                        if (jobObj is Map) {
                          bookingNum = jobObj['bookingNumber'] ?? '—';
                          customerName = jobObj['customerName'] ?? '—';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status == 'paid' 
                                          ? const Color(0xFFD1FAE5) 
                                          : status == 'waived' 
                                              ? const Color(0xFFE2E8F0) 
                                              : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status.toString().toUpperCase(),
                                      style: TextStyle(
                                        color: status == 'paid' 
                                            ? const Color(0xFF065F46) 
                                            : status == 'waived' 
                                                ? const Color(0xFF475569) 
                                                : const Color(0xFF991B1B),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.bookmark_outline_rounded, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Booking Ref: $bookingNum",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Customer: $customerName",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              Text(
                                reason,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "PENALTY AMOUNT",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    "₹${amount.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
