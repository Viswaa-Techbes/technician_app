class Review {
  final String? id;
  final String technicianId;
  final String projectId;
  final String clientName;
  final int rating;
  final String review;
  final DateTime createdAt;

  const Review({
    this.id,
    required this.technicianId,
    required this.projectId,
    required this.clientName,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString(),
      technicianId: json['technicianId']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? 'Anonymous',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      review: json['review']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'technicianId': technicianId,
      'projectId': projectId,
      'clientName': clientName,
      'rating': rating,
      'review': review,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ReviewSummary {
  final String technicianId;
  final String technicianName;
  final double averageRating;
  final int totalReviews;
  final List<Review> reviews;

  const ReviewSummary({
    required this.technicianId,
    required this.technicianName,
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
  });

  static ReviewSummary fromReviews({
    required String technicianId,
    required String technicianName,
    required List<Review> reviews,
  }) {
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length;
    return ReviewSummary(
      technicianId: technicianId,
      technicianName: technicianName,
      averageRating: avg,
      totalReviews: reviews.length,
      reviews: reviews,
    );
  }
}
