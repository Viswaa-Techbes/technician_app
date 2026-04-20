import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.mobileNumber,
    required super.role,
    super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userData = json['data'] ?? json;
    return UserModel(
      id: userData['id'] ?? userData['_id'] ?? '',
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      mobileNumber: userData['mobileNumber'] ?? '',
      role: userData['role'] ?? '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'role': role,
    };
  }
}
