import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_attendance_service.dart';
import 'admin_employee.dart';
import 'admin_employee_service.dart';
import 'work_schedule.dart';
import 'work_schedule_service.dart';
import 'work_site.dart';
import 'work_site_service.dart';

class AdminAttendanceManualCreatePage extends StatefulWidget {
  const AdminAttendanceManualCreatePage({super.key});

  @override
  State<AdminAttendanceManualCreatePage> createState() =>
      _AdminAttendanceManualCreatePageState();
}

class _AdminAttendanceManualCreatePageState extends State<AdminAttendanceManualCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  static const List<String> _statuses = [
    'NORMAL',
    'LATE',
    'EARLY_LEAVE',
    'LATE_AND_EARLY_LEAVE',
    'ABSENT',
  ];

  late final AdminAttendanceService _attendanceService;
  late final AdminEmployeeService _employeeService;
  late final WorkSiteService _workSiteService;
  late final WorkScheduleService _workScheduleService;

  late Future<List<AdminEmployee>> _employeesFuture;
  late Future<List<WorkSite>> _workSitesFuture;
  Future<List<WorkSchedule>>? _schedulesFuture;

  AdminEmployee? _selectedEmployee;
  WorkSite? _selectedWorkSite;
  WorkSchedule? _selectedSchedule;
  String _status = 'NORMAL';
  DateTime? _checkedInAt;
  DateTime? _checkedOutAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();
    const tokenStorage = TokenStorage();

    _attendanceService = AdminAttendanceService(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );
    _employeeService = AdminEmployeeService(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );
    _workSiteService = WorkSiteService(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );
    _workScheduleService = WorkScheduleService(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );

    _employeesFuture = _employeeService.findEmployees();
    _workSitesFuture = _workSiteService.findWorkSites();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _changeWorkSite(WorkSite? workSite) {
    setState(() {
      _selectedWorkSite = workSite;
      _selectedSchedule = null;
      _checkedInAt = null;
      _checkedOutAt = null;
      _schedulesFuture = workSite == null
          ? null
          : _workScheduleService.findByWorkSite(workSite.id);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

    final adminPassword = await _showAdminPasswordDialog();

    if (adminPassword == null || adminPassword.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _attendanceService.createManualAttendance(
        employeeId: _selectedEmployee!.id,
        scheduleId: _selectedSchedule!.id,
        status: _status,
        checkedInAt: _formatDateTimeForApi(checkedInAt),
        checkedOutAt: _formatDateTimeForApi(checkedOutAt),
        reason: reason,
        adminPassword: adminPassword.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('수기 등록 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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

  void _changeSchedule(WorkSchedule? schedule) {
    setState(() {
      _selectedSchedule = schedule;

      if (schedule == null || _status == 'ABSENT') {
        _checkedInAt = null;
        _checkedOutAt = null;
        return;
      }

      _checkedInAt = _scheduleDateTime(schedule, schedule.startTime);
      _checkedOutAt = _scheduleDateTime(schedule, schedule.endTime);
    });
  }

  void _changeStatus(String? status) {
    if (status == null) {
      return;
    }

    setState(() {
      _status = status;

      if (_status == 'ABSENT') {
        _checkedInAt = null;
        _checkedOutAt = null;
        return;
      }

      if (_selectedSchedule != null) {
        _checkedInAt ??=
            _scheduleDateTime(_selectedSchedule!, _selectedSchedule!.startTime);
        _checkedOutAt ??=
            _scheduleDateTime(_selectedSchedule!, _selectedSchedule!.endTime);
      }
    });
  }

  Future<void> _pickCheckedInAt() async {
    final picked = await _pickDateTime(
      current: _checkedInAt,
      fallback: _defaultDateTime(hour: 8),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _checkedInAt = picked;
    });
  }

  Future<void> _pickCheckedOutAt() async {
    final picked = await _pickDateTime(
      current: _checkedOutAt,
      fallback: _defaultDateTime(hour: 17),
    );

    if (picked == null) {
      return;
    }

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

    if (pickedDate == null || !mounted) {
      return null;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );

    if (pickedTime == null) {
      return null;
    }

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _scheduleLabel(WorkSchedule schedule) {
    return '${schedule.workDate} ${schedule.startTime} ~ ${schedule.endTime}';
  }

  DateTime _defaultDateTime({required int hour}) {
    final schedule = _selectedSchedule;

    if (schedule == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour);
    }

    final workDate = DateTime.tryParse(schedule.workDate);
    final baseDate = workDate ?? DateTime.now();

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour);
  }

  DateTime? _scheduleDateTime(WorkSchedule schedule, String time) {
    final normalizedTime = time.length == 5 ? '$time:00' : time;
    return DateTime.tryParse('${schedule.workDate}T$normalizedTime');
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

  @override
  Widget build(BuildContext context) {
    final canEditTime = _status != 'ABSENT';

    return Scaffold(
      appBar: AppBar(title: const Text('수기 등록')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<List<AdminEmployee>>(
              future: _employeesFuture,
              builder: (context, snapshot) {
                final employees = snapshot.data ?? [];

                return DropdownButtonFormField<AdminEmployee>(
                  decoration: const InputDecoration(labelText: '직원'),
                  initialValue: _selectedEmployee,
                  items: employees
                      .map(
                        (employee) => DropdownMenuItem(
                          value: employee,
                          child: Text('${employee.name} (${employee.loginId})'),
                        ),
                      )
                      .toList(),
                  onChanged: snapshot.hasData
                      ? (value) {
                          setState(() {
                            _selectedEmployee = value;
                          });
                        }
                      : null,
                  validator: (value) =>
                      value == null ? '직원을 선택해주세요.' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<WorkSite>>(
              future: _workSitesFuture,
              builder: (context, snapshot) {
                final workSites = snapshot.data ?? [];

                return DropdownButtonFormField<WorkSite>(
                  decoration: const InputDecoration(labelText: '작업 현장'),
                  initialValue: _selectedWorkSite,
                  items: workSites
                      .map(
                        (workSite) => DropdownMenuItem(
                          value: workSite,
                          child: Text(workSite.name),
                        ),
                      )
                      .toList(),
                  onChanged: snapshot.hasData ? _changeWorkSite : null,
                  validator: (value) =>
                      value == null ? '작업 현장을 선택해주세요.' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            if (_selectedWorkSite == null)
              const Text('작업 현장을 선택하면 일정 목록이 표시됩니다.')
            else
              FutureBuilder<List<WorkSchedule>>(
                future: _schedulesFuture,
                builder: (context, snapshot) {
                  final schedules = snapshot.data ?? [];

                  return DropdownButtonFormField<WorkSchedule>(
                    key: ValueKey(_selectedWorkSite?.id),
                    decoration: const InputDecoration(labelText: '작업 일정'),
                    initialValue: _selectedSchedule,
                    items: schedules
                        .map(
                          (schedule) => DropdownMenuItem(
                            value: schedule,
                            child: Text(_scheduleLabel(schedule)),
                          ),
                        )
                        .toList(),
                    onChanged: snapshot.hasData ? _changeSchedule : null,
                    validator: (value) =>
                        value == null ? '작업 일정을 선택해주세요.' : null,
                  );
                },
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '출석 상태'),
              initialValue: _status,
              items: _statuses
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(status)),
                    ),
                  )
                  .toList(),
              onChanged: _changeStatus,
            ),
            const SizedBox(height: 16),
            if (canEditTime) ...[
              _dateTimeTile(
                title: '출근 시간',
                value: _checkedInAt,
                onTap: _selectedSchedule == null ? null : _pickCheckedInAt,
                onClear: _checkedInAt == null
                    ? null
                    : () {
                        setState(() {
                          _checkedInAt = null;
                        });
                      },
              ),
              const SizedBox(height: 12),
              _dateTimeTile(
                title: '퇴근 시간',
                value: _checkedOutAt,
                onTap: _selectedSchedule == null ? null : _pickCheckedOutAt,
                onClear: _checkedOutAt == null
                    ? null
                    : () {
                        setState(() {
                          _checkedOutAt = null;
                        });
                      },
              ),
              const SizedBox(height: 16),
            ] else ...[
              const ListTile(
                title: Text('결석 처리'),
                subtitle: Text('결석 상태는 출근/퇴근 시간을 입력하지 않습니다.'),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: '처리 사유',
                hintText: '예: 무단 결근, 병가, 관리자 확인',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '처리 사유를 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isSaving ? '처리 중...' : '수기 등록'),
            ),
          ],
        ),
      ),
    );
  }
}
