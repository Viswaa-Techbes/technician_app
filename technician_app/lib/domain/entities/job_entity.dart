import '../../models.dart'; // Using existing enum for now

class JobEntity {
  final String id;
  final String serviceName;
  final String description;
  final String customerName;
  final String customerPhone;
  final String address;
  final String time;
  final JobStatus status;
  final String? technicianName;
  final String? technicianId;
  final double price;
  final PaymentStatus paymentStatus;

  JobEntity({
    required this.id,
    required this.serviceName,
    required this.description,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.time,
    required this.status,
    this.technicianName,
    this.technicianId,
    required this.price,
    required this.paymentStatus,
  });
}
