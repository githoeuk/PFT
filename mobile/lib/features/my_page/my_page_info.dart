class MyPageInfo {
  const MyPageInfo({
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

  factory MyPageInfo.fromJson(Map<String, dynamic> json) {
    return MyPageInfo(
      id: json['id'] as int,
      loginId: json['loginId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      active: json['active'] as bool,
    );
  }

  String get roleLabel {
    switch (role) {
      case 'SUPER_ADMIN':
        return '최고 관리자';
      case 'ADMIN':
        return '관리자';
      case 'EMPLOYEE':
        return '직원';
      default:
        return role;
    }
  }
}
