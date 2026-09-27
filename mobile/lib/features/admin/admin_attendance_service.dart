import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_attendance_record.dart';
import 'attendance_adjustment.dart';

class AdminAttendanceService {
  const AdminAttendanceService({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  // 관리자 출석 현황 조회
  Future<List<AdminAttendanceRecord>> findAttendances({
    int? employeeId,
    int? workSiteId,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    final queryParameters = <String, String>{
      if (employeeId != null) 'employeeId': '$employeeId',
      if (workSiteId != null) 'workSiteId': '$workSiteId',
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (status != null) 'status': status,
    };

    final response = await apiClient.getJsonWithAuth(
      '/admin/attendance',
      tokenStorage: tokenStorage,
      queryParameters: queryParameters,
    );

    final data = response['data'];

    if (data is! List) {
      throw const ApiException('INVALID_RESPONSE', '출석 현황 응답 형식이 올바르지 않습니다.');
    }

    return data
        .map(
          (item) =>
              AdminAttendanceRecord.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  // 관리자 출석 수기 수정
  Future<AdminAttendanceRecord> updateAttendanceManually({
    required int attendanceRecordId,
    required String status,
    String? checkedInAt,
    String? checkedOutAt,
    required String reason,
    required String adminPassword,
  }) async {
    final response = await apiClient.patchJsonWithAuth(
      '/admin/attendance/$attendanceRecordId',
      tokenStorage: tokenStorage,
      body: {
        'status': status,
        'checkedInAt': checkedInAt,
        'checkedOutAt': checkedOutAt,
        'reason': reason,
        'adminPassword': adminPassword,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '출석 수정 응답 형식이 올바르지 않습니다.');
    }

    return AdminAttendanceRecord.fromJson(data);
  }

  // 관리자 결석 처리
  Future<AdminAttendanceRecord> createAbsence({
    required int employeeId,
    required int scheduleId,
    required String reason,
    required String adminPassword,
  }) async {
    final response = await apiClient.postJsonWithAuth(
      '/admin/attendance/absences',
      tokenStorage: tokenStorage,
      body: {
        'employeeId': employeeId,
        'scheduleId': scheduleId,
        'reason': reason,
        'adminPassword': adminPassword,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '결석 처리 응답 형식이 올바르지 않습니다.');
    }

    return AdminAttendanceRecord.fromJson(data);
  }

  // 수기 출석 등록 메서드
  Future<AdminAttendanceRecord> createManualAttendance({
    required int employeeId,
    required int scheduleId,
    required String status,
    String? checkedInAt,
    String? checkedOutAt,
    required String reason,
    required String adminPassword,
  }) async {
    final response = await apiClient.postJsonWithAuth(
      '/admin/attendance/manual-records',
      tokenStorage: tokenStorage,
      body: {
        'employeeId': employeeId,
        'scheduleId': scheduleId,
        'status': status,
        'checkedInAt': checkedInAt,
        'checkedOutAt': checkedOutAt,
        'reason': reason,
        'adminPassword': adminPassword,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException('INVALID_RESPONSE', '수기 출석 등록 응답 형식이 올바르지 않습니다.');
    }

    return AdminAttendanceRecord.fromJson(data);
  }

  // 출석 수정 이력 조회
  Future<List<AttendanceAdjustment>> findAdjustments(
    int attendanceRecordId,
  ) async {
    final response = await apiClient.getJsonWithAuth(
      '/admin/attendance/$attendanceRecordId/adjustments',
      tokenStorage: tokenStorage,
    );

    final data = response['data'];

    if (data is! List) {
      throw const ApiException('INVALID_RESPONSE', '출석 수정 이력 응답 형식이 올바르지 않습니다.');
    }

    return data
        .map(
          (item) => AttendanceAdjustment.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
