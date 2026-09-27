import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'work_schedule.dart';

class WorkScheduleService {
  const WorkScheduleService({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  // 현장별 작업 일정 조회
  Future<List<WorkSchedule>> findByWorkSite(int workSiteId) async {
    final response = await apiClient.getJsonWithAuth(
      '/admin/work-schedules/work-sites/$workSiteId',
      tokenStorage: tokenStorage,
    );

    final data = response['data'];

    if (data is! List) {
      throw const ApiException('INVALID_RESPONSE', '작업 일정 응답 형식이 올바르지 않습니다.');
    }

    return data
        .map((item) => WorkSchedule.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // 작업 일정 생성
  Future<WorkSchedule> createWorkSchedule({
    required int workSiteId,
    required String workDate,
    required String startTime,
    required String endTime,
    required int lateGraceMinutes,
    required int earlyLeaveGraceMinutes,
  }) async {
    final response = await apiClient.postJsonWithAuth(
      '/admin/work-schedules',
      tokenStorage: tokenStorage,
      body: {
        'workSiteId': workSiteId,
        'workDate': workDate,
        'startTime': startTime,
        'endTime': endTime,
        'lateGraceMinutes': lateGraceMinutes,
        'earlyLeaveGraceMinutes': earlyLeaveGraceMinutes,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'INVALID_RESPONSE',
        '작업 일정 생성 응답 형식이 올바르지 않습니다.',
      );
    }

    return WorkSchedule.fromJson(data);
  }

  // 작업 일정 수정
  Future<WorkSchedule> updateWorkSchedule({
    required int scheduleId,
    required String workDate,
    required String startTime,
    required String endTime,
    required int lateGraceMinutes,
    required int earlyLeaveGraceMinutes,
  }) async {
    final response = await apiClient.patchJsonWithAuth(
      '/admin/work-schedules/$scheduleId',
      tokenStorage: tokenStorage,
      body: {
        'workDate': workDate,
        'startTime': startTime,
        'endTime': endTime,
        'lateGraceMinutes': lateGraceMinutes,
        'earlyLeaveGraceMinutes': earlyLeaveGraceMinutes,
      },
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'INVALID_RESPONSE',
        '작업 일정 수정 응답 형식이 올바르지 않습니다.',
      );
    }

    return WorkSchedule.fromJson(data);
  }
}
