import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_employee.dart';
import 'admin_employee_service.dart';

class AdminEmployeeFormPage extends StatefulWidget {
  const AdminEmployeeFormPage({
    super.key,
    this.initialEmployee,
  });

  final AdminEmployee? initialEmployee;

  bool get isEditMode => initialEmployee != null;

  @override
  State<AdminEmployeeFormPage> createState() => _AdminEmployeeFormPageState();
}

class _AdminEmployeeFormPageState extends State<AdminEmployeeFormPage> {
  final AdminEmployeeService _employeeService = AdminEmployeeService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late final TextEditingController _loginIdController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final employee = widget.initialEmployee;

    _loginIdController = TextEditingController(text: employee?.loginId ?? '');
    _nameController = TextEditingController(text: employee?.name ?? '');
    _phoneController = TextEditingController(text: employee?.phone ?? '');
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loginId = _loginIdController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (!widget.isEditMode && loginId.isEmpty) {
      _showMessage('아이디를 입력해주세요.');
      return;
    }

    if (name.isEmpty) {
      _showMessage('이름을 입력해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditMode) {
        await _employeeService.updateEmployee(
          employeeId: widget.initialEmployee!.id,
          name: name,
          phone: phone.isEmpty ? null : phone,
        );

        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        final result = await _employeeService.createEmployee(
          loginId: loginId,
          name: name,
          phone: phone.isEmpty ? null : phone,
        );

        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('직원 계정 생성 완료'),
              content: SelectableText(
                '아이디: ${result.employee.loginId}\n'
                '임시 비밀번호: ${result.temporaryPassword}',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );

        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditMode ? '직원 정보 수정' : '직원 계정 생성';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _loginIdController,
            enabled: !widget.isEditMode,
            decoration: const InputDecoration(
              labelText: '아이디',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '이름',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: '전화번호',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: Text(_isSaving ? '저장 중...' : widget.isEditMode ? '수정' : '생성'),
          ),
        ],
      ),
    );
  }
}
