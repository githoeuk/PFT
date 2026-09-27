class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final LoginUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: LoginUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class LoginUser {
  const LoginUser({
    required this.id,
    required this.loginId,
    required this.name,
    required this.phone,
    required this.role,
    required this.active,
  });

  final int id;
  final String loginId;
  final String name;
  final String? phone;
  final String role;
  final bool active;

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: json['id'] as int,
      loginId: json['loginId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      active: json['active'] as bool,
    );
  }
}
