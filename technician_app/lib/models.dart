import 'core/security/rbac_constants.dart';
export 'core/security/rbac_constants.dart';

enum JobStatus { assigned, started, workUploaded, completionRequested, approvedByManager, paymentRequested, paymentPending, paymentDone, completed }

enum PaymentStatus { pending, requested, pendingPayment, verificationPending, paid, rejected }

class Job {
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
  final String? assignedBy;
  final double price;
  final PaymentStatus paymentStatus;
  final String? orderId;
  final String? paymentId;
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
    this.description = '',
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
    this.orderId,
    this.paymentId,
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
    String? description,
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
    String? orderId,
    String? paymentId,
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
      description: description ?? this.description,
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
      orderId: orderId ?? this.orderId,
      paymentId: paymentId ?? this.paymentId,
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
    if (s == 'assigned' || s == 'pending') status = JobStatus.assigned;
    if (s == 'started' || s == 'in_progress' || s == 'inProgress') status = JobStatus.started;
    if (s == 'work_uploaded') status = JobStatus.workUploaded;
    if (s == 'completion_requested') status = JobStatus.completionRequested;
    if (s == 'approved_by_manager' || s == 'pending_approval' || s == 'pendingApproval') status = JobStatus.approvedByManager;
    if (s == 'payment_requested') status = JobStatus.paymentRequested;
    if (s == 'payment_pending') status = JobStatus.paymentPending;
    if (s == 'payment_done') status = JobStatus.paymentDone;
    if (s == 'completed' || s == 'done') status = JobStatus.completed;

    PaymentStatus paymentStatus = PaymentStatus.pending;
    final payment = data['paymentStatus'] as String?;
    if (payment == 'requested') paymentStatus = PaymentStatus.requested;
    if (payment == 'pending_payment' || payment == 'pendingPayment') paymentStatus = PaymentStatus.pendingPayment;
    if (payment == 'paid') paymentStatus = PaymentStatus.paid;
    if (payment == 'verification_pending') paymentStatus = PaymentStatus.verificationPending;
    if (payment == 'rejected') paymentStatus = PaymentStatus.rejected;

    final technician = data['assignedTechnician'];
    final manager = data['assignedManager'];

    return Job(
      id: id,
      serviceName: data['serviceName'] ?? data['title'] ?? 'Field Service',
      description: data['description'] ?? data['paymentDescription'] ?? '',
      customerName: data['customerName'] ?? 'Client',
      customerPhone: data['customerPhone'] ?? 'N/A',
      address: data['address'] ?? data['location'] ?? 'No Address',
      time: data['time'] ?? data['scheduledTime'] ?? 'ASAP',
      status: status,
      technicianName: data['technicianName'] ?? (technician is Map<String, dynamic> ? technician['name'] : null),
      technicianId: data['technicianId'] ?? (technician is Map<String, dynamic> ? technician['_id'] ?? technician['id'] : null),
      assignedBy: data['assignedBy'] ?? (manager is Map<String, dynamic> ? manager['name'] : null),
      price: ((data['amount'] ?? data['price']) ?? 0.0).toDouble(),
      paymentStatus: paymentStatus,
      orderId: data['orderId'],
      paymentId: data['paymentId'],
      notes: data['notes'] ?? '',
      latitude: (data['latitude'] ?? data['lat'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? data['lng'] ?? 0.0).toDouble(),
      googleMapsLink: data['googleMapsLink'],
      fileAttachments: List<String>.from(data['fileAttachments'] ?? data['attachments'] ?? []),
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
  final double? lat;
  final double? lng;

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
    this.lat,
    this.lng,
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
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
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

class User {
  final String id;
  final String name;
  final String mobileNumber;
  final String email;
  final Role role;
  final String token;

  const User({
    required this.id,
    required this.name,
    required this.mobileNumber,
    this.email = '',
    required this.role,
    required this.token,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'User',
      mobileNumber: map['mobileNumber']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: Role.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => Role.technician,
      ),
      token: map['token']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobileNumber': mobileNumber,
      'email': email,
      'role': role.name,
      'token': token,
    };
  }
}

