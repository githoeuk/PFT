import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'auth_service.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final AuthService _authService = AuthService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _newPasswordConfirmController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  void dispose() {
    _loginIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final loginId = _loginIdController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final newPassword = _newPasswordController.text;
    final newPasswordConfirm = _newPasswordConfirmController.text;

    if (loginId.isEmpty || name.isEmpty || phone.isEmpty) {
      _showMessage('아이디, 이름, 휴대폰 번호를 입력해주세요.');
      return;
    }

    if (newPassword.length < 8) {
      _showMessage('새 비밀번호는 8자 이상이어야 합니다.');
      return;
    }

    if (newPassword != newPasswordConfirm) {
      _showMessage('새 비밀번호와 비밀번호 확인이 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.resetPassword(
        loginId: loginId,
        name: name,
        phone: phone,
        newPassword: newPassword,
        newPasswordConfirm: newPasswordConfirm,
      );

      if (!mounted) {
        return;
      }

      _showMessage('비밀번호가 재설정되었습니다. 새 비밀번호로 로그인해주세요.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        title: const Text('비밀번호 재설정'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '계정 정보를 확인한 뒤 새 비밀번호로 변경합니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _loginIdController,
              decoration: const InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '휴대폰 번호',
                hintText: '010-1111-1111',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '새 비밀번호',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordConfirmController,
              obscureText: _obscurePasswordConfirm,
              decoration: InputDecoration(
                labelText: '새 비밀번호 확인',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePasswordConfirm = !_obscurePasswordConfirm;
                    });
                  },
                  icon: Icon(
                    _obscurePasswordConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              onSubmitted: (_) => _resetPassword(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _resetPassword,
              child: Text(_isLoading ? '변경 중...' : '비밀번호 재설정'),
            ),
          ],
        ),
      ),
    );
  }
}
