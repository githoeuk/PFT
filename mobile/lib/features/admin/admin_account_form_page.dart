import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_account.dart';
import 'admin_account_service.dart';

class AdminAccountFormPage extends StatefulWidget {
  const AdminAccountFormPage({
    super.key,
    this.initialAdmin,
  });

  final AdminAccount? initialAdmin;

  bool get isEditMode => initialAdmin != null;

  @override
  State<AdminAccountFormPage> createState() => _AdminAccountFormPageState();
}

class _AdminAccountFormPageState extends State<AdminAccountFormPage> {
  final AdminAccountService _adminAccountService = AdminAccountService(
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

    final admin = widget.initialAdmin;

    _loginIdController = TextEditingController(text: admin?.loginId ?? '');
    _nameController = TextEditingController(text: admin?.name ?? '');
    _phoneController = TextEditingController(text: admin?.phone ?? '');
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
        await _adminAccountService.updateAdmin(
          adminId: widget.initialAdmin!.id,
          name: name,
          phone: phone.isEmpty ? null : phone,
        );

        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        final result = await _adminAccountService.createAdmin(
          loginId: loginId,
          name: name,
          phone: phone.isEmpty ? null : phone,
        );

        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('관리자 계정 생성 완료'),
              content: SelectableText(
                '아이디: ${result.admin.loginId}\n'
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
    final title = widget.isEditMode ? '관리자 정보 수정' : '관리자 계정 생성';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _loginIdController,
                    enabled: !widget.isEditMode,
                    decoration: const InputDecoration(
                      labelText: '아이디',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '이름',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: '전화번호',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(widget.isEditMode ? Icons.save_outlined : Icons.add),
            label: Text(
              _isSaving ? '저장 중...' : widget.isEditMode ? '수정' : '생성',
            ),
          ),
        ],
      ),
    );
  }
}
