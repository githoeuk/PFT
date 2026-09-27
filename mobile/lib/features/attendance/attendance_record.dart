class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.workSiteName,
    required this.workDate,
    required this.checkedInAt,
    required this.checkedOutAt,
    required this.status,
    required this.manualAdjusted,
  });

  final int id;
  final String workSiteName;
  final String workDate;
  final String? checkedInAt;
  final String? checkedOutAt;
  final String status;
  final bool manualAdjusted;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as int,
      workSiteName: json['workSiteName'] as String,
      workDate: json['workDate'] as String,
      checkedInAt: json['checkedInAt'] as String?,
      checkedOutAt: json['checkedOutAt'] as String?,
      status: json['status'] as String,
      manualAdjusted: json['manualAdjusted'] as bool,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'NORMAL':
        return '정상';
      case 'LATE':
        return '지각';
      case 'EARLY_LEAVE':
        return '조퇴';
      case 'LATE_AND_EARLY_LEAVE':
        return '지각/조퇴';
      case 'ABSENT':
        return '결석';
      case 'MANUAL_FIXED':
        return '수기 수정';
      default:
        return status;
    }
  }
}