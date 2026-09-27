import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_employee.dart';
import 'admin_employee_service.dart';
import 'admin_employee_form_page.dart';

class AdminEmployeeListPage extends StatefulWidget {
  const AdminEmployeeListPage({super.key});

  @override
  State<AdminEmployeeListPage> createState() => _AdminEmployeeListPageState();
}

class _AdminEmployeeListPageState extends State<AdminEmployeeListPage> {
  final AdminEmployeeService _employeeService = AdminEmployeeService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late Future<List<AdminEmployee>> _employeesFuture;

  @override
  void initState() {
    super.initState();
    _employeesFuture = _employeeService.findEmployees();
  }

  Future<void> _reload() async {
    setState(() {
      _employeesFuture = _employeeService.findEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('직원 관리'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<AdminEmployee>>(
          future: _employeesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('직원 목록을 불러오지 못했습니다.'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final employees = snapshot.data ?? [];

            if (employees.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Text('등록된 직원이 없습니다.'),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: employees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final employee = employees[index];

                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(employee.name),
                    subtitle: Text(
                      '아이디: ${employee.loginId}\n'
                      '전화번호: ${employee.phone ?? '-'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'resetPassword') {
                          _resetPassword(employee);
                        }

                        if (value == 'deactivate') {
                          _deactivateEmployee(employee);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'resetPassword',
                          child: Text('비밀번호 초기화'),
                        ),
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Text('비활성화'),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => AdminEmployeeFormPage(initialEmployee: employee),
                        ),
                      );

                      if (updated == true) {
                        _reload();
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const AdminEmployeeFormPage(),
            ),
          );

          if (created == true) {
            _reload();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  Future<void> _resetPassword(AdminEmployee employee) async {
    final confirmed = await _confirm(
      title: '비밀번호 초기화',
      content: '${employee.name} 직원의 비밀번호를 초기화할까요?',
      confirmText: '초기화',
    );

    if (!confirmed) return;

    try {
      final temporaryPassword = await _employeeService.resetPassword(employee.id);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('임시 비밀번호 발급'),
            content: SelectableText(
              '아이디: ${employee.loginId}\n'
              '임시 비밀번호: $temporaryPassword',
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
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _deactivateEmployee(AdminEmployee employee) async {
    final confirmed = await _confirm(
      title: '직원 비활성화',
      content: '${employee.name} 직원을 비활성화할까요?',
      confirmText: '비활성화',
    );

    if (!confirmed) return;

    try {
      await _employeeService.deactivateEmployee(employee.id);

      if (!mounted) return;
      _showMessage('직원이 비활성화되었습니다.');
      _reload();
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<bool> _confirm({
    required String title,
    required String content,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDestructive = confirmText.contains('비활성화');

        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(88, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(96, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: isDestructive ? colorScheme.error : null,
                foregroundColor: isDestructive ? colorScheme.onError : null,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
