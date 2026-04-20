import '../../models.dart';
import '../../domain/entities/job_entity.dart';

class JobModel extends JobEntity {
  JobModel({
    required super.id,
    required super.serviceName,
    required super.description,
    required super.customerName,
    required super.customerPhone,
    required super.address,
    required super.time,
    required super.status,
    super.technicianName,
    super.technicianId,
    required super.price,
    required super.paymentStatus,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    // Map existing backend naming to model
    JobStatus status = JobStatus.assigned;
    final s = json['status'] as String?;
    if (s == 'inProgress' || s == 'in_progress') status = JobStatus.inProgress;
    if (s == 'pendingApproval' || s == 'pending') status = JobStatus.pendingApproval;
    if (s == 'completed' || s == 'done') status = JobStatus.completed;

    PaymentStatus paymentStatus = PaymentStatus.pending;
    final payment = json['paymentStatus'] as String?;
    if (payment == 'paid') paymentStatus = PaymentStatus.paid;

    return JobModel(
      id: json['id'] ?? json['_id'] ?? '',
      serviceName: json['serviceName'] ?? json['title'] ?? 'Field Service',
      description: json['description'] ?? '',
      customerName: json['customerName'] ?? 'Client',
      customerPhone: json['customerPhone'] ?? 'N/A',
      address: json['address'] ?? json['location'] ?? 'No Address',
      time: json['time'] ?? 'ASAP',
      status: status,
      technicianName: json['technicianName'],
      technicianId: json['technicianId'],
      price: ((json['amount'] ?? json['price']) ?? 0.0).toDouble(),
      paymentStatus: paymentStatus,
    );
  }
}
