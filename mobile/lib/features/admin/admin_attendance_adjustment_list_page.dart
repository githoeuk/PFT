import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_attendance_record.dart';
import 'admin_attendance_service.dart';
import 'attendance_adjustment.dart';

class AdminAttendanceAdjustmentListPage extends StatefulWidget {
  const AdminAttendanceAdjustmentListPage({
    super.key,
    required this.record,
  });

  final AdminAttendanceRecord record;

  @override
  State<AdminAttendanceAdjustmentListPage> createState() =>
      _AdminAttendanceAdjustmentListPageState();
}

class _AdminAttendanceAdjustmentListPageState
    extends State<AdminAttendanceAdjustmentListPage> {
  final AdminAttendanceService _attendanceService = AdminAttendanceService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late Future<List<AttendanceAdjustment>> _adjustmentsFuture;

  @override
  void initState() {
    super.initState();
    _adjustmentsFuture = _attendanceService.findAdjustments(widget.record.id);
  }

  Future<void> _reload() async {
    final future = _attendanceService.findAdjustments(widget.record.id);

    setState(() {
      _adjustmentsFuture = future;
    });

    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수정 이력'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<AttendanceAdjustment>>(
          future: _adjustmentsFuture,
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
                  const Text('수정 이력을 불러오지 못했습니다.'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final adjustments = snapshot.data ?? [];

            if (adjustments.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Text('수정 이력이 없습니다.'),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: adjustments.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AttendanceSummary(record: widget.record);
                }

                final adjustment = adjustments[index - 1];

                return Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adjustment.createdAtLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text('수정자: ${adjustment.adjustedByName}'),
                        const Divider(height: 24),
                        _ChangeRow(
                          label: '상태',
                          beforeValue: adjustment.beforeStatusLabel,
                          afterValue: adjustment.afterStatusLabel,
                        ),
                        _ChangeRow(
                          label: '출근',
                          beforeValue: adjustment.beforeCheckedInAtLabel,
                          afterValue: adjustment.afterCheckedInAtLabel,
                        ),
                        _ChangeRow(
                          label: '퇴근',
                          beforeValue: adjustment.beforeCheckedOutAtLabel,
                          afterValue: adjustment.afterCheckedOutAtLabel,
                        ),
                        const SizedBox(height: 12),
                        Text('사유: ${adjustment.reason}'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary({required this.record});

  final AdminAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: const Icon(Icons.fact_check_outlined),
        title: Text('${record.employeeName} · ${record.statusLabel}'),
        subtitle: Text(
          '${record.workSiteName}\n'
          '작업일: ${record.workDate}\n'
          '출근: ${record.checkedInAtLabel}\n'
          '퇴근: ${record.checkedOutAtLabel}',
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.label,
    required this.beforeValue,
    required this.afterValue,
  });

  final String label;
  final String beforeValue;
  final String afterValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(label),
          ),
          Expanded(
            child: Text('$beforeValue -> $afterValue'),
          ),
        ],
      ),
    );
  }
}