import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'my_page_info.dart';

class MyPageService {
  const MyPageService({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<MyPageInfo> findMyPage() async {

    final response = await apiClient.getJsonWithAuth(
      '/me',
      tokenStorage: tokenStorage,
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '마이페이지 응답 형식이 올바르지 않습니다.');
    }

    return MyPageInfo.fromJson(data);
  }

  // 마이페이지 수정
  Future<MyPageInfo> updateMyPage({
    required String name,
    String? phone,
  }) async {

    final response = await apiClient.patchJsonWithAuth(
      '/me',
      tokenStorage: tokenStorage,
      body: {
        'name': name,
        'phone': phone,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '마이페이지 수정 응답 형식이 올바르지 않습니다.');
    }

    return MyPageInfo.fromJson(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {

    await apiClient.patchJsonWithAuth(
      '/me/password',
      tokenStorage: tokenStorage,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}