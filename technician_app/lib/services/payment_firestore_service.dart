import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentFirestoreService {
  final FirebaseFirestore _firestore;

  PaymentFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> markPaymentPaid({
    required String jobId,
    required String orderId,
    required String paymentId,
    required double amount,
  }) async {
    final payload = <String, dynamic>{
      'jobId': jobId,
      'orderId': orderId,
      'paymentId': paymentId,
      'amount': amount,
      'paymentStatus': 'paid',
      'updatedAt': FieldValue.serverTimestamp(),
      'paidAt': FieldValue.serverTimestamp(),
    };

    await Future.wait([
      _firestore.collection('jobs').doc(jobId).set(payload, SetOptions(merge: true)),
      _firestore.collection('projects').doc(jobId).set(payload, SetOptions(merge: true)),
    ]);
  }
}
