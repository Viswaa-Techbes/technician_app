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
    if (s == 'started' || s == 'in_progress' || s == 'inProgress') status = JobStatus.started;
    if (s == 'work_uploaded') status = JobStatus.workUploaded;
    if (s == 'completion_requested') status = JobStatus.completionRequested;
    if (s == 'approved_by_manager' || s == 'pending_approval' || s == 'pendingApproval') status = JobStatus.approvedByManager;
    if (s == 'payment_pending') status = JobStatus.paymentPending;
    if (s == 'payment_done') status = JobStatus.paymentDone;
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
