import 'package:customer_app/core/api/api_client.dart';
import 'package:customer_app/core/api/api_endpoints.dart';

class PaymentRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> createOrder({
    required String bookingId,
    required double amount,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.createOrder,
      data: {
        'bookingId': bookingId,
        'amount': amount,
      },
    );
    // Returns order details: { orderId, amount, currency, keyId, key } etc.
    return response['data'] as Map<String, dynamic>? ?? response;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String bookingId,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.verifyPayment,
      data: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
        'bookingId': bookingId,
      },
    );
    return response['data'] as Map<String, dynamic>? ?? response;
  }
}
