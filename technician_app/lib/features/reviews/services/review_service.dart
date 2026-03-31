import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../../../services/mock_data_service.dart';

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
    if (MockDataService.useMock) {
      await MockDataService().submitReview(projectId, rating, review);
      return;
    }
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
    if (MockDataService.useMock) {
      final mockData = await MockDataService().getReviews(technicianId);
      return mockData.map((data) => Review(
        technicianId: data['techId'] ?? '',
        projectId: data['jobId'] ?? '',
        clientName: data['customerName'] ?? 'Client',
        rating: (data['rating'] as num).toInt(),
        review: data['comment'] ?? '',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      )).toList();
    }
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
