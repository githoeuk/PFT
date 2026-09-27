import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'work_site.dart';
import 'work_site_service.dart';

class WorkSiteFormPage extends StatefulWidget {
  const WorkSiteFormPage({super.key, this.initialWorkSite});

  final WorkSite? initialWorkSite;

  bool get isEditMode => initialWorkSite != null;

  @override
  State<WorkSiteFormPage> createState() => _WorkSiteFormPageState();
}

class _WorkSiteFormPageState extends State<WorkSiteFormPage> {
  final WorkSiteService _workSiteService = WorkSiteService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final initialWorkSite = widget.initialWorkSite;

    _nameController = TextEditingController(text: initialWorkSite?.name ?? '');
    _addressController = TextEditingController(
      text: initialWorkSite?.address ?? '',
    );
    _descriptionController = TextEditingController(
      text: initialWorkSite?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showMessage('현장명을 입력해주세요.');
      return;
    }

    if (address.isEmpty) {
      _showMessage('주소를 입력해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditMode) {
        await _workSiteService.updateWorkSite(
          workSiteId: widget.initialWorkSite!.id,
          name: name,
          address: address,
          description: description.isEmpty ? null : description,
        );
      } else {
        await _workSiteService.createWorkSite(
          name: name,
          address: address,
          description: description.isEmpty ? null : description,
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditMode ? '작업 현장 수정' : '작업 현장 등록')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '현장명',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: '주소',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '설명',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
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
