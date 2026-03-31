import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets.dart';
import 'account_details_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/reviews/providers/review_providers.dart';
import 'features/reviews/services/review_service.dart';
import 'features/reviews/screens/technician_reviews_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider);
    final userName = session?.name ?? "Technician";
    final userRole = session?.role.name.toUpperCase() ?? "SENIOR FIELD ENGINEER";

    final reviewsAsync = ref.watch(technicianReviewsProvider(session?.id ?? ''));

    final avgRating = reviewsAsync.maybeWhen(
      data: (reviews) => ReviewService.calculateAverageRating(reviews),
      orElse: () => 0.0,
    );

    final totalReviews = reviewsAsync.maybeWhen(
      data: (reviews) => reviews.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProductionProfileHeader(context, userName, userRole),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionLabel(context, "Performance Metrics"),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          context,
                          avgRating > 0 ? avgRating.toStringAsFixed(1) : "N/A",
                          "Rating",
                          Icons.auto_awesome_rounded,
                          const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('projects')
                              .where('technicianId', isEqualTo: session?.id)
                              .where('status', isEqualTo: 'completed')
                              .snapshots(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.docs.length ?? 0;
                            return _buildMetricTile(
                              context,
                              count.toString(),
                              "Projects",
                              Icons.rocket_launch_rounded,
                              const Color(0xFF2563EB),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionLabel(context, "Preferences & Security"),
                  const SizedBox(height: 16),
                  _buildMenuAction(
                    Icons.rate_review_outlined,
                    "Client Reviews",
                    "View what customers are saying ($totalReviews)",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TechnicianReviewsScreen(
                          technicianId: session?.id ?? '',
                          technicianName: userName,
                        ),
                      ),
                    ),
                  ),
                  _buildMenuAction(
                    Icons.person_outline_rounded,
                    "Account Details",
                    "Manage your personal profile",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AccountDetailsScreen()),
                    ),
                  ),
                  _buildMenuAction(Icons.lock_outline_rounded, "Privacy & Security", "Password and biometric lock"),
                  _buildMenuAction(Icons.notifications_active_outlined, "Notification Center", "Real-time alert preferences"),
                  _buildMenuAction(Icons.support_agent_rounded, "Technical Support", "24/7 priority live assistance"),
                  const SizedBox(height: 48),
                  CustomButton(
                    label: "SIGN OUT",
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    color: const Color(0xFFF43F5E),
                    icon: Icons.power_settings_new_rounded,
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      "App Version v2.4.0 (Production Build)",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionProfileHeader(BuildContext context, String name, String role) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
                ),
                child: const CircleAvatar(
                  radius: 56,
                  backgroundColor: Color(0xFFF8FAFC),
                  child: Icon(Icons.person_rounded, size: 60, color: Color(0xFF1E3A8A)),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            name,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge,
    );
  }

  Widget _buildMetricTile(BuildContext context, String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMenuAction(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: const Color(0xFF475569), size: 22),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
