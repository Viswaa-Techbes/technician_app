import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/features/payment/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});
