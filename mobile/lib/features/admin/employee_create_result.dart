import 'admin_employee.dart';

class EmployeeCreateResult {
  const EmployeeCreateResult({
    required this.employee,
    required this.temporaryPassword,
  });

  final AdminEmployee employee;
  final String temporaryPassword;

  factory EmployeeCreateResult.fromJson(Map<String, dynamic> json) {
    return EmployeeCreateResult(
      employee: AdminEmployee.fromJson(json['employee'] as Map<String, dynamic>),
      temporaryPassword: json['temporaryPassword'] as String,
    );
  }
}