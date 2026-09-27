import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_attendance_manual_create_page.dart';
import 'admin_attendance_edit_page.dart';
import 'admin_attendance_record.dart';
import 'admin_attendance_service.dart';
import 'admin_employee.dart';
import 'admin_employee_service.dart';
import 'work_site.dart';
import 'work_site_service.dart';
import 'admin_attendance_adjustment_list_page.dart';

class AdminAttendanceListPage extends StatefulWidget {
  const AdminAttendanceListPage({super.key});

  @override
  State<AdminAttendanceListPage> createState() =>
      _AdminAttendanceListPageState();
}

class _AdminAttendanceListPageState extends State<AdminAttendanceListPage> {
  final AdminAttendanceService _attendanceService = AdminAttendanceService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  final AdminEmployeeService _employeeService = AdminEmployeeService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  final WorkSiteService _workSiteService = WorkSiteService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late Future<List<AdminAttendanceRecord>> _attendanceFuture;
  late Future<List<AdminEmployee>> _employeesFuture;
  late Future<List<WorkSite>> _workSitesFuture;

  AdminEmployee? _selectedEmployee;
  WorkSite? _selectedWorkSite;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _employeesFuture = _employeeService.findEmployees();
    _workSitesFuture = _workSiteService.findWorkSites();
    _attendanceFuture = _findAttendances();
  }

  Future<List<AdminAttendanceRecord>> _findAttendances() {
    return _attendanceService.findAttendances(
      employeeId: _selectedEmployee?.id,
      workSiteId: _selectedWorkSite?.id,
      startDate: _formatDate(_startDate),
      endDate: _formatDate(_endDate),
      status: _selectedStatus,
    );
  }

  Future<void> _reload() async {
    final future = _findAttendances();

    setState(() {
      _attendanceFuture = future;
    });

    await future;
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedEmployee = null;
      _selectedWorkSite = null;
      _selectedStatus = null;
      _attendanceFuture = _findAttendances();
    });
  }

  void _changeEmployee(AdminEmployee? employee) {
    setState(() {
      _selectedEmployee = employee;
      _attendanceFuture = _findAttendances();
    });
  }

  void _changeWorkSite(WorkSite? workSite) {
    setState(() {
      _selectedWorkSite = workSite;
      _attendanceFuture = _findAttendances();
    });
  }

  void _changeStatus(String? status) {
    setState(() {
      _selectedStatus = status;
      _attendanceFuture = _findAttendances();
    });
  }

  Widget _buildFilterPanel() {
    return _AttendanceFilterPanel(
      employeesFuture: _employeesFuture,
      workSitesFuture: _workSitesFuture,
      selectedEmployee: _selectedEmployee,
      selectedWorkSite: _selectedWorkSite,
      selectedStatus: _selectedStatus,
      startDateLabel: _dateLabel(_startDate),
      endDateLabel: _dateLabel(_endDate),
      onEmployeeChanged: _changeEmployee,
      onWorkSiteChanged: _changeWorkSite,
      onStatusChanged: _changeStatus,
      onStartDateTap: _pickStartDate,
      onEndDateTap: _pickEndDate,
      onClear: _clearFilters,
    );
  }

  Future<void> _openManualCreatePage() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AdminAttendanceManualCreatePage(),
      ),
    );

    if (created == true) {
      _reload();
    }
  }

  void _openAdjustmentListPage(AdminAttendanceRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminAttendanceAdjustmentListPage(record: record),
      ),
    );
  }

  String _latestAdjustedByText(AdminAttendanceRecord record) {
    final latestAdjustedByName = record.latestAdjustedByName;

    if (latestAdjustedByName == null || latestAdjustedByName.isEmpty) {
      return '';
    }

    return '\n처리자: $latestAdjustedByName';
  }

  String _latestReasonText(AdminAttendanceRecord record) {
    final latestReason = record.latestReason;

    if (latestReason == null || latestReason.isEmpty) {
      return '';
    }

    return '\n사유: $latestReason';
  }

  String? _formatDate(DateTime? date) {
    if (date == null) {
      return null;
    }

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _dateLabel(DateTime? date) {
    return _formatDate(date) ?? '선택 안 함';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startDate = picked;

      if (_endDate != null && picked.isAfter(_endDate!)) {
        _endDate = picked;
      }

      _attendanceFuture = _findAttendances();
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _endDate = picked;

      if (_startDate != null && picked.isBefore(_startDate!)) {
        _startDate = picked;
      }

      _attendanceFuture = _findAttendances();
    });
  }

  Future<void> _openEditPage(AdminAttendanceRecord record) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminAttendanceEditPage(record: record),
      ),
    );

    if (updated == true) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('출석 현황')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<AdminAttendanceRecord>>(
          future: _attendanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilterPanel(),
                  const SizedBox(height: 16),
                  const Text('출석 현황을 불러오지 못했습니다.'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final records = snapshot.data ?? [];
            final itemCount = records.isEmpty ? 2 : records.length + 1;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: itemCount,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildFilterPanel();
                }

                if (records.isEmpty) {
                  return const Text('출석 기록이 없습니다.');
                }

                final record = records[index - 1];

                return Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.fact_check_outlined),
                      title: Text(
                        '${record.employeeName} · ${record.statusLabel}',
                      ),
                      subtitle: Text(
                        '${record.workSiteName}\n'
                        '작업일: ${record.workDate}\n'
                        '출근: ${record.checkedInAtLabel}\n'
                        '퇴근: ${record.checkedOutAtLabel}'
                        '${_latestReasonText(record)}'
                        '${_latestAdjustedByText(record)}',
                      ),
                      trailing: record.manualAdjusted
                          ? IconButton(
                              tooltip: '수정 이력',
                              icon: const Icon(Icons.history_outlined),
                              onPressed: () => _openAdjustmentListPage(record),
                            )
                          : const SizedBox.shrink(),
                      onTap: () => _openEditPage(record),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openManualCreatePage,
        icon: const Icon(Icons.add),
        label: const Text('수기 등록'),
      ),
    );
  }
}

class _AttendanceFilterPanel extends StatelessWidget {
  const _AttendanceFilterPanel({
    required this.employeesFuture,
    required this.workSitesFuture,
    required this.selectedEmployee,
    required this.selectedWorkSite,
    required this.selectedStatus,
    required this.onEmployeeChanged,
    required this.onWorkSiteChanged,
    required this.onStatusChanged,
    required this.onClear,
    required this.startDateLabel,
    required this.endDateLabel,
    required this.onStartDateTap,
    required this.onEndDateTap,
  });

  final Future<List<AdminEmployee>> employeesFuture;
  final Future<List<WorkSite>> workSitesFuture;
  final AdminEmployee? selectedEmployee;
  final WorkSite? selectedWorkSite;
  final String? selectedStatus;
  final ValueChanged<AdminEmployee?> onEmployeeChanged;
  final ValueChanged<WorkSite?> onWorkSiteChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;
  final String startDateLabel;
  final String endDateLabel;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<List<AdminEmployee>>(
          future: employeesFuture,
          builder: (context, snapshot) {
            final employees = snapshot.data ?? [];

            return DropdownButtonFormField<AdminEmployee>(
              decoration: const InputDecoration(labelText: '직원'),
              initialValue: selectedEmployee,
              isExpanded: true,
              items: employees
                  .map(
                    (employee) => DropdownMenuItem(
                      value: employee,
                      child: Text('${employee.name} (${employee.loginId})'),
                    ),
                  )
                  .toList(),
              onChanged: snapshot.hasData ? onEmployeeChanged : null,
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<WorkSite>>(
          future: workSitesFuture,
          builder: (context, snapshot) {
            final workSites = snapshot.data ?? [];

            return DropdownButtonFormField<WorkSite>(
              decoration: const InputDecoration(labelText: '작업 현장'),
              initialValue: selectedWorkSite,
              isExpanded: true,
              items: workSites
                  .map(
                    (workSite) => DropdownMenuItem(
                      value: workSite,
                      child: Text(workSite.name),
                    ),
                  )
                  .toList(),
              onChanged: snapshot.hasData ? onWorkSiteChanged : null,
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: '출석 상태'),
          initialValue: selectedStatus,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'NORMAL', child: Text('정상')),
            DropdownMenuItem(value: 'LATE', child: Text('지각')),
            DropdownMenuItem(value: 'EARLY_LEAVE', child: Text('조퇴')),
            DropdownMenuItem(
              value: 'LATE_AND_EARLY_LEAVE',
              child: Text('지각/조퇴'),
            ),
            DropdownMenuItem(value: 'ABSENT', child: Text('결석')),
          ],
          onChanged: onStatusChanged,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onStartDateTap,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('시작일 $startDateLabel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEndDateTap,
                icon: const Icon(Icons.event_outlined),
                label: Text('종료일 $endDateLabel'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('필터 초기화'),
          ),
        ),
      ],
    );
  }
}
