import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_account.dart';
import 'admin_account_create_result.dart';

class AdminAccountService {
  const AdminAccountService({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  // 관리자 계정 목록 조회
  Future<List<AdminAccount>> findAdmins() async {
    final response = await apiClient.getJsonWithAuth(
      '/super-admin/admins',
      tokenStorage: tokenStorage,
    );

    final data = response['data'];

    if (data is! List) {
      throw const ApiException('INVALID_RESPONSE', '관리자 목록 응답 형식이 올바르지 않습니다.');
    }

    return data
        .map((item) => AdminAccount.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 관리자 계정 생성
  Future<AdminAccountCreateResult> createAdmin({
    required String loginId,
    required String name,
    String? phone,
  }) async {
    final response = await apiClient.postJsonWithAuth(
      '/super-admin/admins',
      tokenStorage: tokenStorage,
      body: {
        'loginId': loginId,
        'name': name,
        'phone': phone,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '관리자 생성 응답 형식이 올바르지 않습니다.');
    }

    return AdminAccountCreateResult.fromJson(data);
  }

  // 관리자 계정 수정
  Future<AdminAccount> updateAdmin({
    required int adminId,
    required String name,
    String? phone,
  }) async {
    final response = await apiClient.patchJsonWithAuth(
      '/super-admin/admins/$adminId',
      tokenStorage: tokenStorage,
      body: {
        'name': name,
        'phone': phone,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '관리자 수정 응답 형식이 올바르지 않습니다.');
    }

    return AdminAccount.fromJson(data);
  }

  // 관리자 계정 비밀번호 초기화
  Future<String> resetPassword(int adminId) async {
    final response = await apiClient.patchJsonWithAuth(
      '/super-admin/admins/$adminId/password/reset',
      tokenStorage: tokenStorage,
      body: {},
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '비밀번호 초기화 응답 형식이 올바르지 않습니다.');
    }

    return data['temporaryPassword'] as String;
  }

  // 관리자 계정 비활성화
  Future<void> deactivateAdmin(int adminId) async {
    await apiClient.deleteJsonWithAuth(
      '/super-admin/admins/$adminId',
      tokenStorage: tokenStorage,
    );
  }
}
