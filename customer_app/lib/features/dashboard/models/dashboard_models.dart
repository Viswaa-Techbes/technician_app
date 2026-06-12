class DashboardMetric {
  final String title;
  final String value;
  final String tone;

  const DashboardMetric({
    required this.title,
    required this.value,
    required this.tone,
  });

  factory DashboardMetric.fromJson(Map<String, dynamic> json) {
    return DashboardMetric(
      title: json['title'] as String? ?? '',
      value: json['value'] as String? ?? '0',
      tone: json['tone'] as String? ?? 'emerald',
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? mobileNumber;
  final String? profilePhoto;
  final String? createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.mobileNumber,
    this.profilePhoto,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class UserAddress {
  final String id;
  final String label;
  final String? name;
  final String? mobile;
  final String? address;
  final String addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? formattedAddress;
  final bool isDefault;

  const UserAddress({
    required this.id,
    required this.label,
    this.name,
    this.mobile,
    this.address,
    required this.addressLine1,
    this.addressLine2,
    this.landmark,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.isDefault = false,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      name: json['name'] as String?,
      mobile: json['mobile'] as String?,
      address: json['address'] as String?,
      addressLine1: json['addressLine1'] as String? ?? json['address'] as String? ?? '',
      addressLine2: json['addressLine2'] as String?,
      landmark: json['landmark'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble(),
      formattedAddress: json['formattedAddress'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'name': name,
        'mobile': mobile,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'landmark': landmark,
        'city': city,
        'state': state,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'formattedAddress': formattedAddress,
        'isDefault': isDefault,
      };
}

class UserBooking {
  final String id;
  final String? bookingNumber;
  final String? bookingId;
  final String? serviceName;
  final String? title;
  final String? serviceType;
  final double? amount;
  final double? price;
  final String status;
  final String? bookingStatus;
  final String? paymentStatus;
  final String? bookingDate;
  final String? scheduledDate;
  final String? timeSlot;
  final String? scheduledTime;
  final String? createdAt;
  final String? location;
  final String? technicianName;
  final String? technicianId;
  final double? rating;

  const UserBooking({
    required this.id,
    this.bookingNumber,
    this.bookingId,
    this.serviceName,
    this.title,
    this.serviceType,
    this.amount,
    this.price,
    required this.status,
    this.bookingStatus,
    this.paymentStatus,
    this.bookingDate,
    this.scheduledDate,
    this.timeSlot,
    this.scheduledTime,
    this.createdAt,
    this.location,
    this.technicianName,
    this.technicianId,
    this.rating,
  });

  factory UserBooking.fromJson(Map<String, dynamic> json) {
    final tech = json['assignedTechnician'] as Map<String, dynamic>?;
    return UserBooking(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      bookingNumber: json['bookingNumber'] as String?,
      bookingId: json['bookingId'] as String?,
      serviceName: json['serviceName'] as String?,
      title: json['title'] as String?,
      serviceType: json['serviceType'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      status: json['status'] as String? ?? json['bookingStatus'] as String? ?? 'pending',
      bookingStatus: json['bookingStatus'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      bookingDate: json['bookingDate'] as String?,
      scheduledDate: json['scheduledDate'] as String?,
      timeSlot: json['timeSlot'] as String?,
      scheduledTime: json['scheduledTime'] as String?,
      createdAt: json['createdAt'] as String?,
      location: json['location'] as String?,
      technicianName: tech?['name'] as String?,
      technicianId: tech?['_id'] as String? ?? tech?['id'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}

class UserPayment {
  final String id;
  final String? razorpayPaymentId;
  final double amount;
  final String status;
  final String createdAt;

  const UserPayment({
    required this.id,
    this.razorpayPaymentId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory UserPayment.fromJson(Map<String, dynamic> json) {
    return UserPayment(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class ServiceReport {
  final String jobId;
  final String technician;
  final String completionDate;
  final String? pdfReport;

  const ServiceReport({
    required this.jobId,
    required this.technician,
    required this.completionDate,
    this.pdfReport,
  });

  factory ServiceReport.fromJson(Map<String, dynamic> json) {
    return ServiceReport(
      jobId: json['jobId'] as String? ?? '',
      technician: json['technician'] as String? ?? '',
      completionDate: json['completionDate'] as String? ?? '',
      pdfReport: json['pdfReport'] as String?,
    );
  }
}

class DashboardData {
  final List<DashboardMetric> metrics;
  final UserProfile? profile;
  final List<UserAddress> addresses;
  final List<UserBooking> bookings;
  final List<UserBooking> upcomingBookings;
  final List<UserPayment> payments;
  final List<ServiceReport> serviceReports;

  const DashboardData({
    required this.metrics,
    this.profile,
    required this.addresses,
    required this.bookings,
    required this.upcomingBookings,
    required this.payments,
    required this.serviceReports,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final rawMetrics = data['metrics'] as Map<String, dynamic>?;
    
    final metrics = [
      DashboardMetric(title: 'Upcoming services', value: '${rawMetrics?['upcomingServices'] ?? 0}', tone: 'emerald'),
      DashboardMetric(title: 'Order history', value: '${rawMetrics?['orderHistory'] ?? 0}', tone: 'blue'),
      DashboardMetric(title: 'Saved addresses', value: '${rawMetrics?['savedAddresses'] ?? 0}', tone: 'emerald'),
      DashboardMetric(title: 'Payments', value: '${rawMetrics?['payments'] ?? 0}', tone: 'blue'),
    ];

    return DashboardData(
      metrics: metrics,
      profile: data['profile'] != null ? UserProfile.fromJson(data['profile'] as Map<String, dynamic>) : null,
      addresses: (data['addresses'] as List? ?? []).map((e) => UserAddress.fromJson(e as Map<String, dynamic>)).toList(),
      bookings: (data['bookings'] as List? ?? []).map((e) => UserBooking.fromJson(e as Map<String, dynamic>)).toList(),
      upcomingBookings: (data['upcomingBookings'] as List? ?? []).map((e) => UserBooking.fromJson(e as Map<String, dynamic>)).toList(),
      payments: (data['payments'] as List? ?? []).map((e) => UserPayment.fromJson(e as Map<String, dynamic>)).toList(),
      serviceReports: (data['serviceReports'] as List? ?? []).map((e) => ServiceReport.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
