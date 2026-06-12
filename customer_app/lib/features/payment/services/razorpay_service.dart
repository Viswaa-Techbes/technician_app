import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;
  void Function(PaymentSuccessResponse)? _onSuccess;
  void Function(PaymentFailureResponse)? _onFailure;
  void Function(ExternalWalletResponse)? _onExternalWallet;

  void init({
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onFailure,
    void Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onExternalWallet = onExternalWallet;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onExternalWallet?.call(response);
  }

  void openCheckout({
    required String key,
    required double amount,
    required String orderId,
    required String name,
    required String description,
    required String email,
    required String phone,
  }) {
    final options = {
      'key': key,
      'amount': amount.toInt(),
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {
        'contact': phone,
        'email': email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    _razorpay.open(options);
  }

  void dispose() {
    _razorpay.clear();
  }
}
