import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'auth_service.dart';

class FindLoginIdPage extends StatefulWidget {
  const FindLoginIdPage({super.key});

  @override
  State<FindLoginIdPage> createState() => _FindLoginIdPageState();
}

class _FindLoginIdPageState extends State<FindLoginIdPage> {
  final AuthService _authService = AuthService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _foundLoginId;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _findLoginId() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _showMessage('이름과 휴대폰 번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _foundLoginId = null;
    });

    try {
      final loginId = await _authService.findLoginId(
        name: name,
        phone: phone,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _foundLoginId = loginId;
      });
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
        title: const Text('아이디 찾기'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '가입된 이름과 휴대폰 번호를 입력해주세요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _findLoginId,
              child: Text(_isLoading ? '확인 중...' : '아이디 찾기'),
            ),
            if (_foundLoginId != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '아이디: $_foundLoginId',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
