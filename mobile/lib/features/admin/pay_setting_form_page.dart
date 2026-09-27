import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_employee.dart';
import 'admin_employee_service.dart';
import 'pay_setting.dart';
import 'pay_setting_service.dart';
import 'work_site.dart';

class PaySettingFormPage extends StatefulWidget {
  const PaySettingFormPage({
    super.key,
    required this.workSite,
    this.initialPaySetting,
  });

  final WorkSite workSite;
  final PaySetting? initialPaySetting;

  bool get isEditMode => initialPaySetting != null;

  @override
  State<PaySettingFormPage> createState() => _PaySettingFormPageState();
}

class _PaySettingFormPageState extends State<PaySettingFormPage> {
  final PaySettingService _paySettingService = PaySettingService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  final AdminEmployeeService _employeeService = AdminEmployeeService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late Future<List<AdminEmployee>> _employeesFuture;
  AdminEmployee? _selectedEmployee;

  late final TextEditingController _dailyWageController;
  late final TextEditingController _taxRateController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _employeesFuture = _employeeService.findEmployees();

    final paySetting = widget.initialPaySetting;

    _dailyWageController = TextEditingController(
      text: paySetting == null ? '' : '${paySetting.dailyWage}',
    );
    _taxRateController = TextEditingController(
      text: paySetting == null ? '0.00' : paySetting.taxRate.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _dailyWageController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final dailyWage = int.tryParse(_dailyWageController.text.trim());
    final taxRate = double.tryParse(_taxRateController.text.trim());

    if (!widget.isEditMode && _selectedEmployee == null) {
      _showMessage('직원을 선택해주세요.');
      return;
    }

    if (dailyWage == null || dailyWage <= 0) {
      _showMessage('일급은 0보다 큰 숫자로 입력해주세요.');
      return;
    }

    if (taxRate == null || taxRate < 0 || taxRate > 100) {
      _showMessage('세율은 0 이상 100 이하 숫자로 입력해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditMode) {
        await _paySettingService.updatePaySetting(
          paySettingId: widget.initialPaySetting!.id,
          dailyWage: dailyWage,
          taxRate: taxRate,
        );
      } else {
        await _paySettingService.createPaySetting(
          employeeId: _selectedEmployee!.id,
          workSiteId: widget.workSite.id,
          dailyWage: dailyWage,
          taxRate: taxRate,
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
    final title = widget.isEditMode ? '급여 설정 수정' : '급여 설정 등록';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('현장'),
            subtitle: Text(widget.workSite.name),
          ),
          const SizedBox(height: 12),
          if (widget.isEditMode)
            ListTile(
              title: const Text('직원'),
              subtitle: Text(widget.initialPaySetting!.employeeName),
            )
          else
            FutureBuilder<List<AdminEmployee>>(
              future: _employeesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('직원 목록을 불러오지 못했습니다.\n${snapshot.error}');
                }

                final employees = snapshot.data ?? [];

                return DropdownButtonFormField<AdminEmployee>(
                  value: _selectedEmployee,
                  decoration: const InputDecoration(
                    labelText: '직원',
                    border: OutlineInputBorder(),
                  ),
                  items: employees
                      .map(
                        (employee) => DropdownMenuItem(
                          value: employee,
                          child: Text('${employee.name} (${employee.loginId})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEmployee = value;
                    });
                  },
                );
              },
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _dailyWageController,
            decoration: const InputDecoration(
              labelText: '일급',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _taxRateController,
            decoration: const InputDecoration(
              labelText: '세율(%)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: Text(_isSaving ? '저장 중...' : widget.isEditMode ? '수정' : '등록'),
          ),
        ],
      ),
    );
  }
}
