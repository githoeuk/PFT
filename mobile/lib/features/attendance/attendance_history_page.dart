import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'attendance_record.dart';
import 'attendance_service.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  final AttendanceService _attendanceService = AttendanceService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late Future<List<AttendanceRecord>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _attendanceService.findMyAttendance();
  }

  Future<void> _reload() async {
    setState(() {
      _attendanceFuture = _attendanceService.findMyAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 출석 내역'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<AttendanceRecord>>(
          future: _attendanceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('출석 내역을 불러오지 못했습니다.'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final records = snapshot.data ?? [];

            if (records.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Text('출석 내역이 없습니다.'),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = records[index];

                return Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(record.workSiteName),
                    subtitle: Text(
                      '${record.workDate}\n'
                      '출근: ${record.checkedInAt ?? '-'}\n'
                      '퇴근: ${record.checkedOutAt ?? '-'}',
                    ),
                    trailing: Text(record.statusLabel),
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