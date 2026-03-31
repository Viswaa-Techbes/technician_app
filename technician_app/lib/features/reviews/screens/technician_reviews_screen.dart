import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/review_providers.dart';
import '../services/review_service.dart';
import '../widgets/star_rating_widget.dart';
import '../widgets/review_card_widget.dart';

/// Screen to view all reviews for a specific technician.
/// Used from both Technician Profile and Manager Dashboard.
class TechnicianReviewsScreen extends ConsumerWidget {
  final String technicianId;
  final String technicianName;

  const TechnicianReviewsScreen({
    super.key,
    required this.technicianId,
    required this.technicianName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(technicianReviewsProvider(technicianId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('REVIEWS'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: reviewsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFF43F5E)),
              const SizedBox(height: 16),
              Text(
                'Failed to load reviews',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(technicianReviewsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (reviews) {
          final avgRating = ReviewService.calculateAverageRating(reviews);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Header with technician info and average rating
                      _buildRatingHeader(avgRating, reviews.length),
                      const SizedBox(height: 32),
                      // Rating breakdown
                      _buildRatingBreakdown(reviews),
                    ],
                  ),
                ),
              ),
              // Reviews list
              if (reviews.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 64, color: Color(0xFFE2E8F0)),
                        SizedBox(height: 16),
                        Text(
                          'No reviews yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'ALL REVIEWS',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 2,
                              ),
                            ),
                          );
                        }
                        return ReviewCard(review: reviews[index - 1]);
                      },
                      childCount: reviews.length + 1,
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRatingHeader(double avgRating, int totalReviews) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  const Color(0xFF6366F1).withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                technicianName.isNotEmpty
                    ? technicianName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            technicianName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          AverageRatingBadge(
            averageRating: avgRating,
            totalReviews: totalReviews,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBreakdown(List reviews) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    // Count ratings
    final counts = List.filled(5, 0);
    for (final r in reviews) {
      if (r.rating >= 1 && r.rating <= 5) {
        counts[r.rating - 1]++;
      }
    }
    final maxCount = counts.reduce((a, b) => a > b ? a : b);

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
          const Text(
            'RATING BREAKDOWN',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: Color(0xFF94A3B8),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(5, (index) {
            final stars = 5 - index;
            final count = counts[stars - 1];
            final fraction = maxCount > 0 ? count / maxCount : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$stars',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const Icon(Icons.star_rounded,
                      size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
