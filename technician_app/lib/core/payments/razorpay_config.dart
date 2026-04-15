class RazorpayConfig {
  const RazorpayConfig._();

  static const String keyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_your_key_id',
  );

  static const String companyName = String.fromEnvironment(
    'COMPANY_NAME',
    defaultValue: 'TechBes Services',
  );
}
