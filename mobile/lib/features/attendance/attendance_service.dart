import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'attendance_record.dart';
import 'beacon_scan_result.dart';

class AttendanceService {
  const AttendanceService({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<void> checkIn(BeaconScanResult beacon) async {
   await apiClient.postJsonWithAuth(
     '/employee/attendance/check-in',
     tokenStorage: tokenStorage,
     body: beacon.toRequestBody(),
   );
  }

  Future<void> checkOut(BeaconScanResult beacon) async {
    await apiClient.postJsonWithAuth(
      '/employee/attendance/check-out',
      tokenStorage: tokenStorage,
      body: beacon.toRequestBody(),
    );
  }

  Future<List<AttendanceRecord>> findMyAttendance() async {
    final response = await apiClient.getJsonWithAuth(
      '/employee/attendance',
      tokenStorage: tokenStorage,
    );

    final data = response['data'];

    if (data is! List) {
      throw const ApiException('INVALID_RESPONSE', '출석 내역 응답 형식이 올바르지 않습니다.');
    }

    return data
        .map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
