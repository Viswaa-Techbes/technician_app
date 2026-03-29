enum JobStatus { assigned, inProgress, pendingApproval, completed }

enum PaymentStatus { pending, paid }

class Job {
  final String id;
  final String serviceName;
  final String customerName;
  final String customerPhone;
  final String address;
  final String time;
  final JobStatus status;
  final String? technicianName;
  final String? technicianId;
  final String? assignedBy;
  final double price;
  final PaymentStatus paymentStatus;
  final int? rating;
  final String? reviewComment;
  final Duration timerDuration;
  final DateTime? startTime;
  final String? beforeImagePath;
  final String? afterImagePath;
  final String? notes;

  const Job({
    required this.id,
    required this.serviceName,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.time,
    required this.status,
    this.technicianName,
    this.technicianId,
    this.assignedBy,
    this.price = 0.0,
    this.paymentStatus = PaymentStatus.pending,
    this.rating,
    this.reviewComment,
    this.timerDuration = Duration.zero,
    this.startTime,
    this.beforeImagePath,
    this.afterImagePath,
    this.notes,
  });

  Job copyWith({
    String? id,
    String? serviceName,
    String? customerName,
    String? customerPhone,
    String? address,
    String? time,
    JobStatus? status,
    String? technicianName,
    String? technicianId,
    String? assignedBy,
    double? price,
    PaymentStatus? paymentStatus,
    int? rating,
    String? reviewComment,
    Duration? timerDuration,
    DateTime? startTime,
    String? beforeImagePath,
    String? afterImagePath,
    String? notes,
  }) {
    return Job(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      time: time ?? this.time,
      status: status ?? this.status,
      technicianName: technicianName ?? this.technicianName,
      technicianId: technicianId ?? this.technicianId,
      assignedBy: assignedBy ?? this.assignedBy,
      price: price ?? this.price,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rating: rating ?? this.rating,
      reviewComment: reviewComment ?? this.reviewComment,
      timerDuration: timerDuration ?? this.timerDuration,
      startTime: startTime ?? this.startTime,
      beforeImagePath: beforeImagePath ?? this.beforeImagePath,
      afterImagePath: afterImagePath ?? this.afterImagePath,
      notes: notes ?? this.notes,
    );
  }
}

enum TechnicianStatus { available, busy, offline }

class Technician {
  final String id;
  final String name;
  final TechnicianStatus status;
  final String? currentJobId;
  final String phone;
  final String specialty;
  final String assignedManager;

  const Technician({
    required this.id,
    required this.name,
    required this.status,
    this.currentJobId,
    required this.phone,
    this.specialty = 'General Technician',
    this.assignedManager = 'Manager Mike',
  });
}

class Expense {
  final String id;
  final String description;
  final double amount;
  final String date;
  final String? receiptPath;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.receiptPath,
  });
}
