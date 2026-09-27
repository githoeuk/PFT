import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'my_page_info.dart';
import 'my_page_service.dart';

class MyPageEditPage extends StatefulWidget {
  const MyPageEditPage({
    super.key,
    required this.initialInfo,
  });

  final MyPageInfo initialInfo;

  @override
  State<MyPageEditPage> createState() => _MyPageEditPageState();
}

class _MyPageEditPageState extends State<MyPageEditPage> {
  final MyPageService _myPageService = MyPageService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialInfo.name);
    _phoneController = TextEditingController(text: widget.initialInfo.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showMessage('이름을 입력해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _myPageService.updateMyPage(
        name: name,
        phone: phone.isEmpty ? null : phone,
      );

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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보 수정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            child: Text(_isSaving ? '저장 중...' : '저장'),
          ),
        ],
      ),
    );
  }
}
