import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'features/reviews/providers/review_providers.dart';
import 'features/reviews/services/review_service.dart';
import 'features/reviews/screens/technician_reviews_screen.dart';

class TechnicianDetailScreen extends ConsumerWidget {
  final Technician technician;

  const TechnicianDetailScreen({super.key, required this.technician});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(technicianReviewsProvider(technician.id));

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
      appBar: AppBar(
        title: const Text("TECHNICIAN PROFILE"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileCard(context, avgRating, totalReviews),
            const SizedBox(height: 32),
            _buildSpecialtyCard(),
            const SizedBox(height: 32),
            _buildCurrentJobSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, double avgRating, int totalReviews) {
    Color statusColor = Colors.grey;
    String statusText = "OFFLINE";
    if (technician.status == TechnicianStatus.available) {
      statusColor = const Color(0xFF10B981);
      statusText = "AVAILABLE";
    } else if (technician.status == TechnicianStatus.busy) {
      statusColor = const Color(0xFFEA580C);
      statusText = "ON JOB #${technician.currentJobId}";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 3),
                ),
                child: const CircleAvatar(
                  radius: 48,
                  backgroundColor: Color(0xFFF8FAFC),
                  child: Icon(Icons.person_rounded, size: 56, color: Color(0xFF3B82F6)),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            technician.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildContactAction(Icons.call_rounded, const Color(0xFF1E3A8A)),
              const SizedBox(width: 24),
              _buildContactAction(Icons.message_rounded, const Color(0xFF0EA5E9)),
            ],
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TechnicianReviewsScreen(
                  technicianId: technician.id,
                  technicianName: technician.name,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    avgRating > 0 ? avgRating.toStringAsFixed(1) : "No Ratings",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "($totalReviews reviews)",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFB45309), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAction(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildSpecialtyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DETAILS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 2)),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.engineering_rounded, "Specialty", technician.specialty),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone_rounded, "Phone", technician.phone),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.manage_accounts_rounded, "Assigned To", technician.assignedManager),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentJobSection(BuildContext context) {
    if (technician.status != TechnicianStatus.busy) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CURRENT ASSIGNMENT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 2)),
        const SizedBox(height: 16),
        // Placeholder for the current job card - we will wire this to demo data if needed.
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFEA580C).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFFEA580C)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Job #${technician.currentJobId}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  const Text("View assignment details", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ],
    );
  }
}
