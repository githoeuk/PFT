class WorkSchedule {
  const WorkSchedule({
    required this.id,
    required this.workSiteId,
    required this.workSiteName,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    required this.lateGraceMinutes,
    required this.earlyLeaveGraceMinutes,
  });

  final int id;
  final int workSiteId;
  final String workSiteName;
  final String workDate;
  final String startTime;
  final String endTime;
  final int lateGraceMinutes;
  final int earlyLeaveGraceMinutes;

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    return WorkSchedule(
      id: json['id'] as int,
      workSiteId: json['workSiteId'] as int,
      workSiteName: json['workSiteName'] as String,
      workDate: json['workDate'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      lateGraceMinutes: json['lateGraceMinutes'] as int,
      earlyLeaveGraceMinutes: json['earlyLeaveGraceMinutes'] as int,
    );
  }
}
