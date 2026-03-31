import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../widgets/star_rating_widget.dart';
import 'technician_reviews_screen.dart';

class ManagerReviewsScreen extends StatelessWidget {
  const ManagerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('TECHNICIAN REVIEWS'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          // Grouping logic
          final Map<String, List<Review>> grouped = {};
          for (var doc in docs) {
            final d = doc.data() as Map<String, dynamic>;
            final r = Review(
              technicianId: d['technicianId'] ?? '',
              projectId: d['projectId'] ?? '',
              clientName: d['clientName'] ?? '',
              rating: d['rating'] ?? 0,
              review: d['review'] ?? '',
              createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
            grouped.putIfAbsent(r.technicianId, () => []).add(r);
          }

          final summaries = grouped.entries.map((e) {
            return ReviewSummary.fromReviews(
              technicianId: e.key,
              technicianName: 'Technician', // We'd need a join to get real names
              reviews: e.value,
            );
          }).toList();
          
          return _buildTechnicianListView(summaries);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
     return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Color(0xFFE2E8F0)),
            SizedBox(height: 16),
            Text('No reviews submitted yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF94A3B8))),
            SizedBox(height: 6),
            Text('Reviews will appear after job completions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFCBD5E1))),
          ],
        ),
      );
  }

  Widget _buildTechnicianListView(List<ReviewSummary> summaries) {
    summaries.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        return _buildTechnicianReviewCard(context, summaries[index], index);
      },
    );
  }

  Widget _buildTechnicianReviewCard(
    BuildContext context,
    ReviewSummary summary,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TechnicianReviewsScreen(
              technicianId: summary.technicianId,
              technicianName: summary.technicianName,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: index == 0
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: index == 0
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Avatar
              Container(
                width: 52,
                height: 52,
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
                    summary.technicianName.isNotEmpty
                        ? summary.technicianName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.technicianName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StarRatingWidget(
                          rating: summary.averageRating.round(),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          summary.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.totalReviews} ${summary.totalReviews == 1 ? 'review' : 'reviews'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
