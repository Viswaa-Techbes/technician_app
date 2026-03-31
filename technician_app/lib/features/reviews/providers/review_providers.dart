import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

/// Provider for the ReviewService instance.
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

/// Fetches reviews for a specific technician.
final technicianReviewsProvider = FutureProvider.family.autoDispose<List<Review>, String>(
  (ref, techId) async {
    final service = ref.watch(reviewServiceProvider);
    return service.fetchReviewsByTechnician(technicianId: techId);
  },
);

/// Manages the state for submitting a review.
class ReviewSubmitNotifier extends StateNotifier<AsyncValue<void>> {
  final ReviewService _service;

  ReviewSubmitNotifier(this._service) : super(const AsyncValue.data(null));

  Future<bool> submit({
    required String technicianId,
    required String projectId,
    required String clientName,
    required int rating,
    required String review,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.submitReview(
        technicianId: technicianId,
        projectId: projectId,
        clientName: clientName,
        rating: rating,
        review: review,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final reviewSubmitProvider = StateNotifierProvider.autoDispose<ReviewSubmitNotifier, AsyncValue<void>>(
  (ref) => ReviewSubmitNotifier(ref.watch(reviewServiceProvider)),
);
