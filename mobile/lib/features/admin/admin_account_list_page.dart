import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'admin_account.dart';
import 'admin_account_form_page.dart';
import 'admin_account_service.dart';

class AdminAccountListPage extends StatefulWidget {
  const AdminAccountListPage({super.key});

  @override
  State<AdminAccountListPage> createState() => _AdminAccountListPageState();
}

class _AdminAccountListPageState extends State<AdminAccountListPage> {
  final AdminAccountService _adminAccountService = AdminAccountService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late Future<List<AdminAccount>> _adminsFuture;

  @override
  void initState() {
    super.initState();
    _adminsFuture = _adminAccountService.findAdmins();
  }

  Future<void> _reload() async {
    setState(() {
      _adminsFuture = _adminAccountService.findAdmins();
    });
  }

  Future<void> _openCreatePage() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminAccountFormPage()),
    );

    if (created == true) {
      _reload();
    }
  }

  Future<void> _openEditPage(AdminAccount admin) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminAccountFormPage(initialAdmin: admin),
      ),
    );

    if (updated == true) {
      _reload();
    }
  }

  Future<void> _resetPassword(AdminAccount admin) async {
    final confirmed = await _confirm(
      title: '비밀번호 초기화',
      content: '${admin.name} 관리자의 비밀번호를 초기화할까요?',
      confirmText: '초기화',
    );

    if (!confirmed) return;

    try {
      final temporaryPassword = await _adminAccountService.resetPassword(
        admin.id,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('임시 비밀번호 발급'),
            content: SelectableText(
              '아이디: ${admin.loginId}\n'
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

  Future<void> _deactivateAdmin(AdminAccount admin) async {
    final confirmed = await _confirm(
      title: '관리자 비활성화',
      content: '${admin.name} 관리자 계정을 비활성화할까요?',
      confirmText: '비활성화',
    );

    if (!confirmed) return;

    try {
      await _adminAccountService.deactivateAdmin(admin.id);

      if (!mounted) return;
      _showMessage('관리자 계정이 비활성화되었습니다.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리자 계정 관리')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<AdminAccount>>(
          future: _adminsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StateMessage(
                    icon: Icons.error_outline,
                    title: '관리자 목록을 불러오지 못했습니다.',
                    message: snapshot.error.toString(),
                  ),
                ],
              );
            }

            final admins = snapshot.data ?? [];

            if (admins.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _StateMessage(
                    icon: Icons.admin_panel_settings_outlined,
                    title: '등록된 관리자 계정이 없습니다.',
                    message: '관리자 계정이 생성되면 목록에 표시됩니다.',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: admins.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final admin = admins[index];

                return _AdminAccountCard(
                  admin: admin,
                  onTap: () => _openEditPage(admin),
                  onResetPassword: () => _resetPassword(admin),
                  onDeactivate: () => _deactivateAdmin(admin),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePage,
        icon: const Icon(Icons.add),
        label: const Text('관리자 추가'),
      ),
    );
  }
}

class _AdminAccountCard extends StatelessWidget {
  const _AdminAccountCard({
    required this.admin,
    required this.onTap,
    required this.onResetPassword,
    required this.onDeactivate,
  });

  final AdminAccount admin;
  final VoidCallback onTap;
  final VoidCallback onResetPassword;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.admin_panel_settings_outlined,
            color: colorScheme.primary,
          ),
        ),
        title: Text(
          admin.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '아이디: ${admin.loginId}\n'
            '전화번호: ${admin.phone ?? '-'}',
          ),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: '관리자 계정 작업',
          onSelected: (value) {
            if (value == 'resetPassword') {
              onResetPassword();
            }

            if (value == 'deactivate') {
              onDeactivate();
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
        onTap: onTap,
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          Icon(icon, size: 40, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
