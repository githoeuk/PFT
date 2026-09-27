import 'admin_account.dart';

class AdminAccountCreateResult {
  const AdminAccountCreateResult({
    required this.admin,
    required this.temporaryPassword,
  });

  final AdminAccount admin;
  final String temporaryPassword;

  factory AdminAccountCreateResult.fromJson(Map<String, dynamic> json) {
    return AdminAccountCreateResult(
      admin: AdminAccount.fromJson(json['admin'] as Map<String, dynamic>),
      temporaryPassword: json['temporaryPassword'] as String,
    );
  }
}
