import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Legacy Payment Service adapter.
/// Migrated from obsolete Firestore writes to MongoDB Backend REST APIs as the single source of truth.
class PaymentFirestoreService {
  final ApiService? _api;

  PaymentFirestoreService({ApiService? api}) : _api = api;

  Future<void> markPaymentPaid({
    required String jobId,
    required String orderId,
    required String paymentId,
    required double amount,
  }) async {
    debugPrint('[PaymentService] Marking payment paid via Backend REST API for job $jobId');
    if (_api != null) {
      await _api.updateJobStatus(jobId, 'payment_done', note: 'Paid via order $orderId, payment $paymentId');
    }
  }
}
