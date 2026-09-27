class AttendanceAdjustment {
  const AttendanceAdjustment({
    required this.id,
    required this.attendanceRecordId,
    required this.adjustedByUserId,
    required this.adjustedByName,
    required this.beforeStatus,
    required this.afterStatus,
    required this.beforeCheckedInAt,
    required this.afterCheckedInAt,
    required this.beforeCheckedOutAt,
    required this.afterCheckedOutAt,
    required this.reason,
    required this.createdAt,
  });

  final int id;
  final int attendanceRecordId;
  final int adjustedByUserId;
  final String adjustedByName;
  final String? beforeStatus;
  final String afterStatus;
  final String? beforeCheckedInAt;
  final String? afterCheckedInAt;
  final String? beforeCheckedOutAt;
  final String? afterCheckedOutAt;
  final String reason;
  final String createdAt;

  factory AttendanceAdjustment.fromJson(Map<String, dynamic> json) {
    return AttendanceAdjustment(
      id: json['id'] as int,
      attendanceRecordId: json['attendanceRecordId'] as int,
      adjustedByUserId: json['adjustedByUserId'] as int,
      adjustedByName: json['adjustedByName'] as String,
      beforeStatus: json['beforeStatus'] as String?,
      afterStatus: json['afterStatus'] as String,
      beforeCheckedInAt: json['beforeCheckedInAt'] as String?,
      afterCheckedInAt: json['afterCheckedInAt'] as String?,
      beforeCheckedOutAt: json['beforeCheckedOutAt'] as String?,
      afterCheckedOutAt: json['afterCheckedOutAt'] as String?,
      reason: json['reason'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  String get beforeStatusLabel => _statusLabel(beforeStatus);

  String get afterStatusLabel => _statusLabel(afterStatus);

  String get beforeCheckedInAtLabel => _formatDateTimeForView(beforeCheckedInAt);

  String get afterCheckedInAtLabel => _formatDateTimeForView(afterCheckedInAt);

  String get beforeCheckedOutAtLabel =>
      _formatDateTimeForView(beforeCheckedOutAt);

  String get afterCheckedOutAtLabel =>
      _formatDateTimeForView(afterCheckedOutAt);

  String get createdAtLabel => _formatDateTimeForView(createdAt);

  static String _statusLabel(String? status) {
    switch (status) {
      case null:
        return '-';
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