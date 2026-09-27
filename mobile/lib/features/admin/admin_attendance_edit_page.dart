import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_attendance_record.dart';
import 'admin_attendance_service.dart';

class AdminAttendanceEditPage extends StatefulWidget {
  const AdminAttendanceEditPage({super.key, required this.record});

  final AdminAttendanceRecord record;

  @override
  State<AdminAttendanceEditPage> createState() =>
      _AdminAttendanceEditPageState();
}

class _AdminAttendanceEditPageState extends State<AdminAttendanceEditPage> {
  final AdminAttendanceService _attendanceService = AdminAttendanceService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  static const List<String> _statuses = [
    'NORMAL',
    'LATE',
    'EARLY_LEAVE',
    'LATE_AND_EARLY_LEAVE',
    'ABSENT',
    'MANUAL_FIXED',
  ];

  late String _status;
  DateTime? _checkedInAt;
  DateTime? _checkedOutAt;
  final TextEditingController _reasonController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _status = widget.record.status;
    _checkedInAt = _parseDateTime(widget.record.checkedInAt);
    _checkedOutAt = _parseDateTime(widget.record.checkedOutAt);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickCheckedInAt() async {
    final picked = await _pickDateTime(
      current: _checkedInAt,
      fallback: _defaultDateTime(hour: 8),
    );

    if (picked == null) return;

    setState(() {
      _checkedInAt = picked;
    });
  }

  Future<void> _pickCheckedOutAt() async {
    final picked = await _pickDateTime(
      current: _checkedOutAt,
      fallback: _defaultDateTime(hour: 17),
    );

    if (picked == null) return;

    setState(() {
      _checkedOutAt = picked;
    });
  }

  Future<DateTime?> _pickDateTime({
    required DateTime? current,
    required DateTime fallback,
  }) async {
    final initialDateTime = current ?? fallback;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );

    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _save() async {
    final reason = _reasonController.text.trim();
    final checkedInAt = _status == 'ABSENT' ? null : _checkedInAt;
    final checkedOutAt = _status == 'ABSENT' ? null : _checkedOutAt;

    if (_status != 'ABSENT' && checkedInAt == null) {
      _showMessage('결석이 아닌 상태에는 출근 시간이 필요합니다.');
      return;
    }

    if (checkedInAt != null &&
        checkedOutAt != null &&
        checkedInAt.isAfter(checkedOutAt)) {
      _showMessage('출근 시간이 퇴근 시간보다 이후일 수 없습니다.');
      return;
    }

    if (reason.isEmpty) {
      _showMessage('수정 사유를 입력해주세요.');
      return;
    }

    final adminPassword = await _showAdminPasswordDialog();

    if (adminPassword == null || adminPassword.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _attendanceService.updateAttendanceManually(
        attendanceRecordId: widget.record.id,
        status: _status,
        checkedInAt: _formatDateTimeForApi(checkedInAt),
        checkedOutAt: _formatDateTimeForApi(checkedOutAt),
        reason: reason,
        adminPassword: adminPassword.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  DateTime _defaultDateTime({required int hour}) {
    final workDate = DateTime.tryParse(widget.record.workDate);
    final baseDate = workDate ?? DateTime.now();

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour);
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  String _formatDateTimeForView(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }

  String? _formatDateTimeForApi(DateTime? value) {
    if (value == null) {
      return null;
    }

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$year-$month-${day}T$hour:$minute:00';
  }

  String _statusLabel(String status) {
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

  Widget _dateTimeTile({
    required String title,
    required DateTime? value,
    required VoidCallback? onTap,
    required VoidCallback? onClear,
  }) {
    return ListTile(
      enabled: onTap != null,
      title: Text(title),
      subtitle: Text(_formatDateTimeForView(value)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(
              tooltip: '시간 비우기',
              icon: const Icon(Icons.close),
              onPressed: onClear,
            ),
          const Icon(Icons.calendar_month_outlined),
        ],
      ),
      onTap: onTap,
    );
  }

  Future<String?> _showAdminPasswordDialog() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('관리자 비밀번호 확인'),
          content: TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '관리자 비밀번호',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              Navigator.of(context).pop(controller.text);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('확인'),
            ),
          ],
        );
      },
    ).whenComplete(() => controller.dispose());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final canEditTime = _status != 'ABSENT';

    return Scaffold(
      appBar: AppBar(title: const Text('출석 수기 수정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(record.employeeName),
            subtitle: Text('${record.workSiteName} · ${record.workDate}'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: '출석 상태',
              border: OutlineInputBorder(),
            ),
            items: _statuses
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(_statusLabel(status)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _status = value;

                if (_status == 'ABSENT') {
                  _checkedInAt = null;
                  _checkedOutAt = null;
                }
              });
            },
          ),
          const SizedBox(height: 12),
          _dateTimeTile(
            title: '출근 시간',
            value: _checkedInAt,
            onTap: canEditTime ? _pickCheckedInAt : null,
            onClear: canEditTime && _checkedInAt != null
                ? () {
                    setState(() {
                      _checkedInAt = null;
                    });
                  }
                : null,
          ),
          const SizedBox(height: 12),
          _dateTimeTile(
            title: '퇴근 시간',
            value: _checkedOutAt,
            onTap: canEditTime ? _pickCheckedOutAt : null,
            onClear: canEditTime && _checkedOutAt != null
                ? () {
                    setState(() {
                      _checkedOutAt = null;
                    });
                  }
                : null,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: '수정 사유',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: Text(_isSaving ? '저장 중...' : '수정'),
          ),
        ],
      ),
    );
  }
}
