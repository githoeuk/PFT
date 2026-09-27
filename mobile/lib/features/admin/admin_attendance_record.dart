class AdminAttendanceRecord {
  const AdminAttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.scheduleId,
    required this.workSiteId,
    required this.workSiteName,
    required this.workDate,
    required this.checkedInAt,
    required this.checkedOutAt,
    required this.status,
    required this.manualAdjusted,
    required this.latestReason,
    required this.latestAdjustedByName,
  });

  final int id;
  final int employeeId;
  final String employeeName;
  final int scheduleId;
  final int workSiteId;
  final String workSiteName;
  final String workDate;
  final String? checkedInAt;
  final String? checkedOutAt;
  final String status;
  final bool manualAdjusted;
  final String? latestReason;
  final String? latestAdjustedByName;

  factory AdminAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceRecord(
      id: json['id'] as int,
      employeeId: json['employeeId'] as int,
      employeeName: json['employeeName'] as String,
      scheduleId: json['scheduleId'] as int,
      workSiteId: json['workSiteId'] as int,
      workSiteName: json['workSiteName'] as String,
      workDate: json['workDate'] as String,
      checkedInAt: json['checkedInAt'] as String?,
      checkedOutAt: json['checkedOutAt'] as String?,
      status: json['status'] as String,
      manualAdjusted: json['manualAdjusted'] as bool,
      latestReason: json['latestReason'] as String?,
      latestAdjustedByName: json['latestAdjustedByName'] as String?,
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

  String get checkedInAtLabel => _formatDateTimeForView(checkedInAt);

  String get checkedOutAtLabel => _formatDateTimeForView(checkedOutAt);

  static String _formatDateTimeForView(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final dateTime = DateTime.tryParse(value);

    if (dateTime == null) {
      return value;
    }

    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }
}
