import 'package:flutter/material.dart';

/// Interactive star rating picker (for forms) and static display widget.
class StarRatingWidget extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onRatingChanged;
  final Color activeColor;
  final Color inactiveColor;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 32,
    this.interactive = false,
    this.onRatingChanged,
    this.activeColor = const Color(0xFFF59E0B),
    this.inactiveColor = const Color(0xFFE2E8F0),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final isFilled = index < rating;
        return GestureDetector(
          onTap: interactive ? () => onRatingChanged?.call(index + 1) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(interactive ? 4 : 1),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: isFilled ? activeColor : inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}

/// Compact average rating display with star + number.
class AverageRatingBadge extends StatelessWidget {
  final double averageRating;
  final int totalReviews;

  const AverageRatingBadge({
    super.key,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFEF3C7).withValues(alpha: 0.8),
            const Color(0xFFFDE68A).withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
          const SizedBox(width: 8),
          Text(
            averageRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }
}
