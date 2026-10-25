class ApartmentBlockModel {
  final String name;
  final int floors;
  final int flatsCount;

  ApartmentBlockModel({
    required this.name,
    this.floors = 1,
    this.flatsCount = 0,
  });

  factory ApartmentBlockModel.fromJson(Map<String, dynamic> json) {
    return ApartmentBlockModel(
      name: json['name']?.toString() ?? '',
      floors: int.tryParse(json['floors']?.toString() ?? '1') ?? 1,
      flatsCount: int.tryParse(json['flatsCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class AssociationUserModel {
  final String name;
  final String mobileNumber;
  final String email;

  AssociationUserModel({
    required this.name,
    required this.mobileNumber,
    required this.email,
  });

  factory AssociationUserModel.fromJson(Map<String, dynamic> json) {
    return AssociationUserModel(
      name: json['name']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class ApartmentModel {
  final String id;
  final String name;
  final String address;
  final String locality;
  final String city;
  final String state;
  final String pincode;
  final String contactPerson;
  final String contactPhone;
  final String contactEmail;
  final int totalFlats;
  final List<ApartmentBlockModel> blocks;
  final List<AssociationUserModel> associationUsers;

  ApartmentModel({
    required this.id,
    required this.name,
    required this.address,
    required this.locality,
    required this.city,
    required this.state,
    required this.pincode,
    required this.contactPerson,
    required this.contactPhone,
    required this.contactEmail,
    required this.totalFlats,
    required this.blocks,
    required this.associationUsers,
  });

  factory ApartmentModel.fromJson(Map<String, dynamic> json) {
    return ApartmentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address'] is String ? json['address'] : (json['address']?['street'] ?? ''),
      locality: json['locality']?.toString() ?? '',
      city: json['city']?.toString() ?? 'Bangalore',
      state: json['state']?.toString() ?? 'Karnataka',
      pincode: json['pincode']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString() ?? '',
      contactEmail: json['contactEmail']?.toString() ?? '',
      totalFlats: int.tryParse(json['totalFlats']?.toString() ?? '0') ?? 0,
      blocks: (json['blocks'] as List<dynamic>?)
              ?.map((b) => ApartmentBlockModel.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      associationUsers: (json['associationUsers'] as List<dynamic>?)
              ?.map((u) => AssociationUserModel.fromJson(u as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EmergencyContactModel {
  final String name;
  final String phone;
  final String relation;

  EmergencyContactModel({
    required this.name,
    required this.phone,
    required this.relation,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      relation: json['relation']?.toString() ?? json['relationship']?.toString() ?? '',
    );
  }
}

class ResidentProfileModel {
  final String residentId;
  final String name;
  final String phone;
  final String flatNumber;
  final String block;
  final String floor;
  final String residentType;
  final String status;
  final EmergencyContactModel? emergencyContact;

  ResidentProfileModel({
    required this.residentId,
    required this.name,
    required this.phone,
    required this.flatNumber,
    required this.block,
    required this.floor,
    required this.residentType,
    required this.status,
    this.emergencyContact,
  });

  factory ResidentProfileModel.fromJson(Map<String, dynamic> json) {
    return ResidentProfileModel(
      residentId: json['residentId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['mobileNumber']?.toString() ?? '',
      flatNumber: json['flatNumber']?.toString() ?? '',
      block: json['block']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '',
      residentType: json['residentType']?.toString() ?? 'owner',
      status: json['status']?.toString() ?? 'active',
      emergencyContact: json['emergencyContact'] != null && json['emergencyContact'] is Map<String, dynamic>
          ? EmergencyContactModel.fromJson(json['emergencyContact'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApartmentResidentData {
  final ApartmentModel? apartment;
  final ResidentProfileModel? resident;
  final Map<String, dynamic>? user;

  ApartmentResidentData({
    this.apartment,
    this.resident,
    this.user,
  });

  factory ApartmentResidentData.fromJson(Map<String, dynamic> json) {
    return ApartmentResidentData(
      apartment: json['apartment'] != null ? ApartmentModel.fromJson(json['apartment'] as Map<String, dynamic>) : null,
      resident: json['resident'] != null ? ResidentProfileModel.fromJson(json['resident'] as Map<String, dynamic>) : null,
      user: json['user'] as Map<String, dynamic>?,
    );
  }
}
