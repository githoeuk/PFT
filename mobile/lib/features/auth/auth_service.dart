import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'login_response.dart';

class AuthService {
  const AuthService({required this.apiClient, required this.tokenStorage});

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  // 로그인
  Future<LoginResponse> login({
    required String loginId,
    required String password,
    required bool autoLogin,
  }) async {
    final response = await apiClient.postJson(
      '/auth/login',
      body: {'loginId': loginId, 'password': password},
    );

    final data = response['data'] as Map<String, dynamic>;
    final loginResponse = LoginResponse.fromJson(data);

    await tokenStorage.saveAccessToken(loginResponse.accessToken);
    await tokenStorage.saveRefreshToken(loginResponse.refreshToken);
    await tokenStorage.saveLastLoginId(loginId);
    await tokenStorage.saveAutoLogin(autoLogin);

    return loginResponse;
  }

  // 토큰 재발급
  Future<String> refreshAccessToken() async {
    final refreshToken = await tokenStorage.readRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException('NO_REFRESH_TOKEN', '저장된 refreshToken이 없습니다.');
    }

    final response = await apiClient.postJson(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );

    final data = response['data'] as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;

    await tokenStorage.saveAccessToken(accessToken);

    return accessToken;
  }

  // 로그아웃
  Future<void> logout() async {
    final refreshToken = await tokenStorage.readRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await apiClient.postJson(
          '/auth/logout',
          body: {'refreshToken': refreshToken},
        );
      }
    } finally {
      await tokenStorage.clearLoginSession();
    }
  }

  // 아이디 찾기
  Future<String> findLoginId({
    required String name,
    required String phone,
  }) async {
    final response = await apiClient.postJson(
      '/auth/login-id/find',
      body: {
        'name': name,
        'phone': phone,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return data['loginId'] as String;
  }

  // 비밀번호 재설정
  Future<void> resetPassword({
    required String loginId,
    required String name,
    required String phone,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await apiClient.postJson(
      '/auth/password/reset',
      body: {
        'loginId': loginId,
        'name': name,
        'phone': phone,
        'newPassword': newPassword,
        'newPasswordConfirm': newPasswordConfirm,
      },
    );
  }
}
