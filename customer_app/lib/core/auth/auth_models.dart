/// Auth data models mirroring `features/auth/types/auth.ts` from the web app.

class AuthUser {
  final String? id;
  final String? name;
  final String email;
  final String? phone;
  final String role;
  final String? token;

  const AuthUser({
    this.id,
    this.name,
    required this.email,
    this.phone,
    this.role = 'user',
    this.token,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? json['_id'] as String? ?? json['userId'] as String?,
      name: json['name'] as String?,
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String? ?? json['mobileNumber'] as String?,
      role: (json['role'] as String?) ?? 'user',
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
      };
}

class LoginPayload {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginPayload({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim().toLowerCase(),
        'password': password,
        'rememberMe': rememberMe,
      };
}

class SignupPayload {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String emailVerificationToken;

  const SignupPayload({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.emailVerificationToken,
  });

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'phone': phone.trim(),
        'mobileNumber': phone.trim(),
        'emailVerificationToken': emailVerificationToken,
      };
}

class LoginResponse {
  final AuthUser user;
  final String token;

  const LoginResponse({required this.user, required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userData = json['data']?['user'] ?? json['user'];
    final token = json['data']?['token'] ?? json['token'] ?? '';
    return LoginResponse(
      user: AuthUser.fromJson(userData is Map<String, dynamic> ? userData : {}),
      token: token as String,
    );
  }
}

class SessionResponse {
  final bool authenticated;
  final AuthUser? user;

  const SessionResponse({required this.authenticated, this.user});

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      authenticated: json['authenticated'] as bool? ?? false,
      user: json['user'] != null
          ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OtpResponse {
  final bool success;
  final String message;
  final int? expiresInSeconds;

  const OtpResponse({
    required this.success,
    required this.message,
    this.expiresInSeconds,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      expiresInSeconds: json['expiresInSeconds'] as int?,
    );
  }
}

class OtpVerifyResponse {
  final bool success;
  final String message;
  final String emailVerificationToken;

  const OtpVerifyResponse({
    required this.success,
    required this.message,
    required this.emailVerificationToken,
  });

  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      emailVerificationToken:
          json['data']?['emailVerificationToken'] as String? ?? '',
    );
  }
}
