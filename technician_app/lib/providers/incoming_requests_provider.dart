import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomingJobRequest {
  final String jobId;
  final String customerName;
  final String serviceName;
  final String address;
  final String distanceKm;
  final double amount;
  final String date;
  final String timeSlot;
  final DateTime expiresAt;

  IncomingJobRequest({
    required this.jobId,
    required this.customerName,
    required this.serviceName,
    required this.address,
    required this.distanceKm,
    required this.amount,
    required this.date,
    required this.timeSlot,
    required this.expiresAt,
  });

  factory IncomingJobRequest.fromJson(Map<String, dynamic> json) {
    return IncomingJobRequest(
      jobId: json['jobId'] ?? '',
      customerName: json['customerName'] ?? json['bookingId'] ?? '',
      serviceName: json['serviceName'] ?? json['title'] ?? '',
      address: json['address'] ?? json['location'] ?? '',
      distanceKm: json['distanceKm']?.toString() ?? '?',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] ?? json['bookingDate'] ?? '',
      timeSlot: json['timeSlot'] ?? 'TBD',
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(seconds: 90)),
    );
  }
}

class IncomingRequestsNotifier extends StateNotifier<List<IncomingJobRequest>> {
  IncomingRequestsNotifier() : super([]);

  void addRequest(IncomingJobRequest request) {
    state = [...state.where((r) => r.jobId != request.jobId), request];
  }

  void removeRequest(String jobId) {
    state = state.where((r) => r.jobId != jobId).toList();
  }

  void clearExpired() {
    final now = DateTime.now();
    state = state.where((r) => r.expiresAt.isAfter(now)).toList();
  }
}

final incomingRequestsProvider = StateNotifierProvider<IncomingRequestsNotifier, List<IncomingJobRequest>>((ref) {
  return IncomingRequestsNotifier();
});
