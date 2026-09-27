import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'pay_setting.dart';

class PaySettingService {
  const PaySettingService({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  // 현장별 급여 설정 조회
  Future<List<PaySetting>> findByWorkSite(int workSiteId) async {
    final response = await apiClient.getJsonWithAuth(
      '/admin/pay-settings/work-sites/$workSiteId',
      tokenStorage: tokenStorage,
    );

    final data = response['data'];

    if (data is! List) {
      throw const ApiException('INVALID_RESPONSE', '급여 설정 응답 형식이 올바르지 않습니다.');
    }

    return data
        .map((item) => PaySetting.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 급여 설정 생성
  Future<PaySetting> createPaySetting({
    required int employeeId,
    required int workSiteId,
    required int dailyWage,
    required double taxRate,
  }) async {
    final response = await apiClient.postJsonWithAuth(
      '/admin/pay-settings',
      tokenStorage: tokenStorage,
      body: {
        'employeeId': employeeId,
        'workSiteId': workSiteId,
        'dailyWage': dailyWage,
        'taxRate': taxRate,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '급여 설정 생성 응답 형식이 올바르지 않습니다.');
    }

    return PaySetting.fromJson(data);
  }

  // 급여 설정 수정
  Future<PaySetting> updatePaySetting({
    required int paySettingId,
    required int dailyWage,
    required double taxRate,
  }) async {
    final response = await apiClient.patchJsonWithAuth(
      '/admin/pay-settings/$paySettingId',
      tokenStorage: tokenStorage,
      body: {
        'dailyWage': dailyWage,
        'taxRate': taxRate,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '급여 설정 수정 응답 형식이 올바르지 않습니다.');
    }

    return PaySetting.fromJson(data);
  }

  // 급여 설정 비활성화
  Future<void> deactivatePaySetting(int paySettingId) async {
    await apiClient.deleteJsonWithAuth(
      '/admin/pay-settings/$paySettingId',
      tokenStorage: tokenStorage,
    );
  }
}