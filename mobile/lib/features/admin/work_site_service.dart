import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'work_site.dart';

class WorkSiteService {
  const WorkSiteService({required this.apiClient, required this.tokenStorage});

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  // 작업 현장 조회
  Future<List<WorkSite>> findWorkSites() async {
    final response = await apiClient.getJsonWithAuth(
      '/admin/work-sites',
      tokenStorage: tokenStorage,
    );

    final data = response['data'];

    if (data is! List) {
      throw const ApiException('INVALID_RESPONSE', '작업 현장 응답 형식이 올바르지 않습니다.');
    }

    return data
        .map((item) => WorkSite.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 작업 현장 생성
  Future<WorkSite> createWorkSite({
    required String name,
    required String address,
    String? description,
  }) async {
    final response = await apiClient.postJsonWithAuth(
      '/admin/work-sites',
      tokenStorage: tokenStorage,
      body: {'name': name, 'address': address, 'description': description},
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'INVALID_RESPONSE',
        '작업 현장 생성 응답 형식이 올바르지 않습니다.',
      );
    }

    return WorkSite.fromJson(data);
  }

  // 작업 현장 수정
  Future<WorkSite> updateWorkSite({
    required int workSiteId,
    required String name,
    required String address,
    String? description,
  }) async {
    final response = await apiClient.patchJsonWithAuth(
      '/admin/work-sites/$workSiteId',
      tokenStorage: tokenStorage,
      body: {'name': name, 'address': address, 'description': description},
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'INVALID_RESPONSE',
        '작업 현장 수정 응답 형식이 올바르지 않습니다.',
      );
    }

    return WorkSite.fromJson(data);
  }

  // 작업 현장 비활성화
  Future<void> deactivateWorkSite(int workSiteId) async {
    await apiClient.deleteJsonWithAuth(
      '/admin/work-sites/$workSiteId',
      tokenStorage: tokenStorage,
    );
  }
}
