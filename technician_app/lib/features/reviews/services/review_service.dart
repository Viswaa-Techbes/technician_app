import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ReviewService();

  /// Submit a new review for a technician after job completion.
  Future<void> submitReview({
    required String technicianId,
    required String projectId,
    required String clientName,
    required int rating,
    required String review,
  }) async {
    final docRef = _db.collection('reviews').doc();
    await docRef.set({
      'technicianId': technicianId,
      'projectId': projectId,
      'clientName': clientName,
      'rating': rating,
      'review': review,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch all reviews for a specific technician.
  Future<List<Review>> fetchReviewsByTechnician({
    required String technicianId,
  }) async {
    final snapshot = await _db.collection('reviews')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Review(
        technicianId: data['technicianId'] ?? '',
        projectId: data['projectId'] ?? '',
        clientName: data['clientName'] ?? 'Client',
        rating: (data['rating'] ?? 0),
        review: data['review'] ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  /// Calculate average rating from a list of reviews.
  static double calculateAverageRating(List<Review> reviews) {
    if (reviews.isEmpty) return 0.0;
    final total = reviews.map((r) => r.rating).reduce((a, b) => a + b);
    return total / reviews.length;
  }
}
