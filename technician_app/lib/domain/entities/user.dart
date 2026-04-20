class User {
  final String id;
  final String name;
  final String email;
  final String mobileNumber;
  final String role;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.role,
    this.token,
  });
}
