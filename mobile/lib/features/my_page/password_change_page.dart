import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'my_page_service.dart';

class PasswordChangePage extends StatefulWidget {
  const PasswordChangePage({super.key});

  @override
  State<PasswordChangePage> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage> {
  final MyPageService _myPageService = MyPageService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _newPasswordConfirmController =
      TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final newPasswordConfirm = _newPasswordConfirmController.text;

    if (currentPassword.isEmpty) {
      _showMessage('현재 비밀번호를 입력해주세요.');
      return;
    }

    if (newPassword.length < 8) {
      _showMessage('새 비밀번호는 8자 이상이어야 합니다.');
      return;
    }

    if (newPassword != newPasswordConfirm) {
      _showMessage('새 비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _myPageService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;
      _showMessage('비밀번호가 변경되었습니다.');
      Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 변경'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _currentPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '현재 비밀번호',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '새 비밀번호',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordConfirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '새 비밀번호 확인',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSaving ? null : _changePassword,
            child: Text(_isSaving ? '변경 중...' : '비밀번호 변경'),
          ),
        ],
      ),
    );
  }
}
