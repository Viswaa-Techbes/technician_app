import '../../models.dart';
import '../../core/security/rbac_constants.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.mobileNumber,
    required super.role,
    required super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userData = json['data']?['user'] ?? json['data'] ?? json['user'] ?? json;
    final token = json['data']?['token'] ?? json['token'] ?? '';
    
    return UserModel(
      id: userData['id'] ?? userData['_id'] ?? '',
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      mobileNumber: userData['mobileNumber'] ?? '',
      role: Role.values.firstWhere(
        (e) => e.name == (userData['role'] ?? 'technician'),
        orElse: () => Role.technician,
      ),
      token: token.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'role': role.name,
      'token': token,
    };
  }
}
