import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'beacon.dart';
import 'beacon_service.dart';
import 'work_site.dart';

class BeaconFormPage extends StatefulWidget {
  const BeaconFormPage({super.key, required this.workSite, this.initialBeacon});

  final WorkSite workSite;
  final Beacon? initialBeacon;

  bool get isEditMode => initialBeacon != null;

  @override
  State<BeaconFormPage> createState() => _BeaconFormPageState();
}

class _BeaconFormPageState extends State<BeaconFormPage> {
  final BeaconService _beaconService = BeaconService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late final TextEditingController _uuidController;
  late final TextEditingController _majorController;
  late final TextEditingController _minorController;
  late final TextEditingController _nameController;
  late final TextEditingController _rssiThresholdController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final beacon = widget.initialBeacon;

    _uuidController = TextEditingController(text: beacon?.uuid ?? '');
    _majorController = TextEditingController(text: '${beacon?.major ?? ''}');
    _minorController = TextEditingController(text: '${beacon?.minor ?? ''}');
    _nameController = TextEditingController(text: beacon?.name ?? '');
    _rssiThresholdController = TextEditingController(
      text: '${beacon?.rssiThreshold ?? -75}',
    );
  }

  @override
  void dispose() {
    _uuidController.dispose();
    _majorController.dispose();
    _minorController.dispose();
    _nameController.dispose();
    _rssiThresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uuid = _uuidController.text.trim();
    final major = int.tryParse(_majorController.text.trim());
    final minor = int.tryParse(_minorController.text.trim());
    final name = _nameController.text.trim();
    final rssiThreshold = int.tryParse(_rssiThresholdController.text.trim());

    if (uuid.isEmpty) {
      _showMessage('UUID를 입력해주세요.');
      return;
    }

    if (major == null) {
      _showMessage('Major는 숫자로 입력해주세요.');
      return;
    }

    if (minor == null) {
      _showMessage('Minor는 숫자로 입력해주세요.');
      return;
    }

    if (name.isEmpty) {
      _showMessage('비콘명을 입력해주세요.');
      return;
    }

    if (rssiThreshold == null) {
      _showMessage('RSSI 기준값은 숫자로 입력해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditMode) {
        await _beaconService.updateBeacon(
          beaconId: widget.initialBeacon!.id,
          workSiteId: widget.workSite.id,
          uuid: uuid,
          major: major,
          minor: minor,
          name: name,
          rssiThreshold: rssiThreshold,
        );
      } else {
        await _beaconService.createBeacon(
          workSiteId: widget.workSite.id,
          uuid: uuid,
          major: major,
          minor: minor,
          name: name,
          rssiThreshold: rssiThreshold,
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
    final title = widget.isEditMode ? '비콘 수정' : '비콘 등록';

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
          TextField(
            controller: _uuidController,

            decoration: const InputDecoration(
              labelText: 'UUID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _majorController,

            decoration: const InputDecoration(
              labelText: 'Major',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minorController,

            decoration: const InputDecoration(
              labelText: 'Minor',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '비콘명',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rssiThresholdController,
            decoration: const InputDecoration(
              labelText: 'RSSI 기준값',
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
