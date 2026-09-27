class AdminAccount {
  const AdminAccount({
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

  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    return AdminAccount(
      id: json['id'] as int,
      loginId: json['loginId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      active: json['active'] as bool,
    );
  }
}
