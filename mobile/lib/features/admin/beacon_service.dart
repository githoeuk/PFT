import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'beacon.dart';

class BeaconService {
  const BeaconService({required this.apiClient, required this.tokenStorage});

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  // 현장별 비콘 목록 조회
  Future<List<Beacon>> findByWorkSite(int workSiteId) async {
    final response = await apiClient.getJsonWithAuth(
      '/admin/beacons/work-sites/$workSiteId',
      tokenStorage: tokenStorage,
    );

    final data = response['data'];

    if (data is! List) {
      throw const ApiException('INVALID_RESPONSE', '비콘 응답 형식이 올바르지 않습니다.');
    }

    return data
        .map((item) => Beacon.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 비콘 생성
  Future<Beacon> createBeacon({
    required int workSiteId,
    required String uuid,
    required int major,
    required int minor,
    required String name,
    required int rssiThreshold,
  }) async {
    final response = await apiClient.postJsonWithAuth(
      '/admin/beacons',
      tokenStorage: tokenStorage,
      body: {
        'workSiteId': workSiteId,
        'uuid': uuid,
        'major': major,
        'minor': minor,
        'name': name,
        'rssiThreshold': rssiThreshold,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '비콘 생성 응답 형식이 올바르지 않습니다.');
    }

    return Beacon.fromJson(data);
  }

  // 비콘 수정
  Future<Beacon> updateBeacon({
    required int beaconId,
    required int workSiteId,
    required String uuid,
    required int major,
    required int minor,
    required String name,
    required int rssiThreshold,
  }) async {
    final response = await apiClient.patchJsonWithAuth(
      '/admin/beacons/$beaconId',
      tokenStorage: tokenStorage,
      body: {
        'workSiteId': workSiteId,
        'uuid': uuid,
        'major': major,
        'minor': minor,
        'name': name,
        'rssiThreshold': rssiThreshold,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '비콘 수정 응답 형식이 올바르지 않습니다.');
    }

    return Beacon.fromJson(data);
  }

  // 비콘 비활성화
  Future<void> deactivateBeacon(int beaconId) async {
    await apiClient.deleteJsonWithAuth(
      '/admin/beacons/$beaconId',
      tokenStorage: tokenStorage,
    );
  }
}
