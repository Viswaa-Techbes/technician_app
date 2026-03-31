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
  final double? latitude;
  final double? longitude;
  final String? googleMapsLink;
  final List<String>? fileAttachments;

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
    this.latitude,
    this.longitude,
    this.googleMapsLink,
    this.fileAttachments,
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
    double? latitude,
    double? longitude,
    String? googleMapsLink,
    List<String>? fileAttachments,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
      fileAttachments: fileAttachments ?? this.fileAttachments,
    );
  }

  factory Job.fromFirestore(Map<String, dynamic> data, String id) {
    JobStatus status = JobStatus.assigned;
    final s = data['status'] as String?;
    if (s == 'inProgress' || s == 'in_progress') status = JobStatus.inProgress;
    if (s == 'pendingApproval' || s == 'pending') status = JobStatus.pendingApproval;
    if (s == 'completed' || s == 'done') status = JobStatus.completed;

    return Job(
      id: id,
      serviceName: data['serviceName'] ?? 'Field Service',
      customerName: data['customerName'] ?? 'Client',
      customerPhone: data['customerPhone'] ?? 'N/A',
      address: data['address'] ?? 'No Address',
      time: data['time'] ?? 'ASAP',
      status: status,
      technicianName: data['technicianName'],
      technicianId: data['technicianId'],
      assignedBy: data['assignedBy'],
      price: (data['price'] ?? 0.0).toDouble(),
      notes: data['notes'] ?? '',
      latitude: (data['latitude'] ?? data['lat'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? data['lng'] ?? 0.0).toDouble(),
      googleMapsLink: data['googleMapsLink'],
      fileAttachments: List<String>.from(data['fileAttachments'] ?? []),
    );
  }
}

enum TechnicianStatus { available, busy, offline }

class Technician {
  final String id;
  final String name;
  final String email;
  final TechnicianStatus status;
  final String? currentJobId;
  final String phone;
  final String specialty;
  final String assignedManager;
  final double performance;
  final int completedJobs;
  final bool isOnline;

  const Technician({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.currentJobId,
    required this.phone,
    this.specialty = 'General Technician',
    this.assignedManager = 'Manager Mike',
    this.performance = 0.0,
    this.completedJobs = 0,
    this.isOnline = false,
  });

  factory Technician.fromFirestore(Map<String, dynamic> data, String id) {
    TechnicianStatus status = TechnicianStatus.offline;
    final s = data['status'] as String?;
    if (s == 'available') status = TechnicianStatus.available;
    if (s == 'busy') status = TechnicianStatus.busy;

    return Technician(
      id: id,
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      status: status,
      currentJobId: data['currentJobId'],
      phone: data['phone'] ?? 'N/A',
      specialty: data['specialty'] ?? 'General Technician',
      performance: (data['performance'] ?? 0.0).toDouble(),
      completedJobs: data['completedJobs'] ?? 0,
      isOnline: data['isOnline'] ?? false,
    );
  }
}

class Expense {
  final String id;
  final String description;
  final double amount;
  final String date;
  final String status;
  final String? receiptUrl;
  final String? projectId;
  final String? technicianId;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
    this.receiptUrl,
    this.projectId,
    this.technicianId,
  });
}
