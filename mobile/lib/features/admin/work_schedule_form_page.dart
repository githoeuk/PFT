import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'work_schedule.dart';
import 'work_schedule_service.dart';
import 'work_site.dart';

class WorkScheduleFormPage extends StatefulWidget {
  const WorkScheduleFormPage({
    super.key,
    required this.workSite,
    this.initialSchedule,
  });

  final WorkSite workSite;
  final WorkSchedule? initialSchedule;

  bool get isEditMode => initialSchedule != null;

  @override
  State<WorkScheduleFormPage> createState() => _WorkScheduleFormPageState();
}

class _WorkScheduleFormPageState extends State<WorkScheduleFormPage> {
  final WorkScheduleService _workScheduleService = WorkScheduleService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late DateTime _workDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late final TextEditingController _lateGraceController;
  late final TextEditingController _earlyLeaveGraceController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final schedule = widget.initialSchedule;

    _workDate = schedule == null
        ? DateTime.now()
        : DateTime.parse(schedule.workDate);

    _startTime = _parseTimeOfDay(schedule?.startTime ?? '08:00:00');
    _endTime = _parseTimeOfDay(schedule?.endTime ?? '17:00:00');

    _lateGraceController = TextEditingController(
      text: '${schedule?.lateGraceMinutes ?? 5}',
    );
    _earlyLeaveGraceController = TextEditingController(
      text: '${schedule?.earlyLeaveGraceMinutes ?? 5}',
    );
  }

  @override
  void dispose() {
    _lateGraceController.dispose();
    _earlyLeaveGraceController.dispose();
    super.dispose();
  }

  Future<void> _pickWorkDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _workDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _workDate = picked;
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked == null) return;

    setState(() {
      _startTime = picked;
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked == null) return;

    setState(() {
      _endTime = picked;
    });
  }

  Future<void> _save() async {
    final lateGraceMinutes = int.tryParse(_lateGraceController.text.trim());
    final earlyLeaveGraceMinutes = int.tryParse(
      _earlyLeaveGraceController.text.trim(),
    );

    if (lateGraceMinutes == null || lateGraceMinutes < 0) {
      _showMessage('지각 유예 시간은 0 이상 숫자로 입력해주세요.');
      return;
    }

    if (earlyLeaveGraceMinutes == null || earlyLeaveGraceMinutes < 0) {
      _showMessage('조퇴 유예 시간은 0 이상 숫자로 입력해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditMode) {
        await _workScheduleService.updateWorkSchedule(
          scheduleId: widget.initialSchedule!.id,
          workDate: _formatDate(_workDate),
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          lateGraceMinutes: lateGraceMinutes,
          earlyLeaveGraceMinutes: earlyLeaveGraceMinutes,
        );
      } else {
        await _workScheduleService.createWorkSchedule(
          workSiteId: widget.workSite.id,
          workDate: _formatDate(_workDate),
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          lateGraceMinutes: lateGraceMinutes,
          earlyLeaveGraceMinutes: earlyLeaveGraceMinutes,
        );
      }

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

  TimeOfDay _parseTimeOfDay(String value) {
    final parts = value.split(':');

    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditMode ? '작업 일정 수정' : '작업 일정 등록';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('현장'),
            subtitle: Text(widget.workSite.name),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('작업일'),
            subtitle: Text(_formatDate(_workDate)),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: _pickWorkDate,
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('출근 시간'),
            subtitle: Text(_formatTime(_startTime)),
            trailing: const Icon(Icons.schedule_outlined),
            onTap: _pickStartTime,
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('퇴근 시간'),
            subtitle: Text(_formatTime(_endTime)),
            trailing: const Icon(Icons.schedule_outlined),
            onTap: _pickEndTime,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lateGraceController,
            decoration: const InputDecoration(
              labelText: '지각 유예 시간(분)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _earlyLeaveGraceController,
            decoration: const InputDecoration(
              labelText: '조퇴 유예 시간(분)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              _isSaving
                  ? '저장 중...'
                  : widget.isEditMode
                  ? '수정'
                  : '등록',
            ),
          ),
        ],
      ),
    );
  }
}
