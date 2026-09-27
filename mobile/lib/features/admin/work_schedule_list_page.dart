import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'work_schedule.dart';
import 'work_schedule_form_page.dart';
import 'work_schedule_service.dart';
import 'work_site.dart';

class WorkScheduleListPage extends StatefulWidget {
  const WorkScheduleListPage({super.key, required this.workSite});

  final WorkSite workSite;

  @override
  State<WorkScheduleListPage> createState() => _WorkScheduleListPageState();
}

class _WorkScheduleListPageState extends State<WorkScheduleListPage> {
  final WorkScheduleService _workScheduleService = WorkScheduleService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late Future<List<WorkSchedule>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _schedulesFuture = _workScheduleService.findByWorkSite(widget.workSite.id);
  }

  Future<void> _reload() async {
    setState(() {
      _schedulesFuture = _workScheduleService.findByWorkSite(
        widget.workSite.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.workSite.name} 일정')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<WorkSchedule>>(
          future: _schedulesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('작업 일정을 불러오지 못했습니다.'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final schedules = snapshot.data ?? [];

            if (schedules.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [Text('등록된 작업 일정이 없습니다.')],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final schedule = schedules[index];

                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.event_note_outlined),
                    title: Text(schedule.workDate),
                    subtitle: Text(
                      '출근 ${schedule.startTime} / 퇴근 ${schedule.endTime}\n'
                      '지각 유예 ${schedule.lateGraceMinutes}분 / '
                      '조퇴 유예 ${schedule.earlyLeaveGraceMinutes}분',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => WorkScheduleFormPage(
                            workSite: widget.workSite,
                            initialSchedule: schedule,
                          ),
                        ),
                      );

                      if (updated == true) {
                        _reload();
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => WorkScheduleFormPage(workSite: widget.workSite),
            ),
          );

          if (created == true) {
            _reload();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
