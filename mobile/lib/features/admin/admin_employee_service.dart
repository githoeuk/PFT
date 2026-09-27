import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_employee.dart';
import 'employee_create_result.dart';

class AdminEmployeeService {
  const AdminEmployeeService({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  // 직원 목록 조회
  Future<List<AdminEmployee>> findEmployees() async {
    final response = await apiClient.getJsonWithAuth(
      '/admin/employees',
      tokenStorage: tokenStorage,
    );

    final data = response['data'];

    if (data is! List) {
      throw const ApiException('INVALID_RESPONSE', '직원 목록 응답 형식이 올바르지 않습니다.');
    }

    return data
        .map((item) => AdminEmployee.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 직원 생성
  Future<EmployeeCreateResult> createEmployee({
    required String loginId,
    required String name,
    String? phone,
  }) async {
    final response = await apiClient.postJsonWithAuth(
      '/admin/employees',
      tokenStorage: tokenStorage,
      body: {
        'loginId': loginId,
        'name': name,
        'phone': phone,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '직원 생성 응답 형식이 올바르지 않습니다.');
    }

    return EmployeeCreateResult.fromJson(data);
  }

  // 직원 정보 수정
  Future<AdminEmployee> updateEmployee({
    required int employeeId,
    required String name,
    String? phone,
  }) async {
    final response = await apiClient.patchJsonWithAuth(
      '/admin/employees/$employeeId',
      tokenStorage: tokenStorage,
      body: {
        'name': name,
        'phone': phone,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '직원 수정 응답 형식이 올바르지 않습니다.');
    }

    return AdminEmployee.fromJson(data);
  }

  // 직원 비밀번호 초기화
  Future<String> resetPassword(int employeeId) async {
    final response = await apiClient.patchJsonWithAuth(
      '/admin/employees/$employeeId/password/reset',
      tokenStorage: tokenStorage,
      body: {},
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '비밀번호 초기화 응답 형식이 올바르지 않습니다.');
    }

    return data['temporaryPassword'] as String;
  }

  // 직원 비활성화
  Future<void> deactivateEmployee(int employeeId) async {
    await apiClient.deleteJsonWithAuth(
      '/admin/employees/$employeeId',
      tokenStorage: tokenStorage,
    );
  }
}