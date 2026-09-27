import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../auth/auth_service.dart';
import '../my_page/my_page.dart';
import 'admin_attendance_list_page.dart';
import 'admin_account_list_page.dart';
import 'beacon_site_select_page.dart';
import 'admin_employee_list_page.dart';
import 'pay_setting_site_select_page.dart';
import 'work_schedule_site_select_page.dart';
import 'work_site_list_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({
    super.key,
    required this.userName,
    required this.role,
  });

  final String userName;
  final String role;

  bool get isSuperAdmin => role == 'SUPER_ADMIN';

  Future<void> _logout(BuildContext context) async {
    final tokenStorage = const TokenStorage();
    final authService = AuthService(
      apiClient: ApiClient(),
      tokenStorage: tokenStorage,
    );

    await authService.logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = isSuperAdmin ? '최고 관리자' : '관리자';
    final menuItems = [
      if (isSuperAdmin)
        _AdminMenuItem(
          icon: Icons.admin_panel_settings_outlined,
          title: '관리자 계정 관리',
          description: '관리자 계정 생성, 수정, 비활성화',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminAccountListPage()),
            );
          },
        ),
      _AdminMenuItem(
        icon: Icons.people_outline,
        title: '직원 관리',
        description: '직원 계정 생성, 수정, 비활성화',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminEmployeeListPage()),
          );
        },
      ),
      _AdminMenuItem(
        icon: Icons.apartment_outlined,
        title: '작업 현장 관리',
        description: '현장 정보와 활성 상태 관리',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const WorkSiteListPage()));
        },
      ),
      _AdminMenuItem(
        icon: Icons.event_note_outlined,
        title: '작업 일정 관리',
        description: '작업일, 출근 시간, 퇴근 시간 설정',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WorkScheduleSiteSelectPage()),
          );
        },
      ),
      _AdminMenuItem(
        icon: Icons.bluetooth_searching,
        title: '비콘 관리',
        description: '현장별 비콘과 RSSI 기준 관리',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BeaconSiteSelectPage()),
          );
        },
      ),
      _AdminMenuItem(
        icon: Icons.fact_check_outlined,
        title: '출석 현황',
        description: '출석 조회, 수기 수정, 수기 등록',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminAttendanceListPage()),
          );
        },
      ),
      _AdminMenuItem(
        icon: Icons.payments_outlined,
        title: '급여 설정',
        description: '직원별 일급과 세율 설정',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaySettingSiteSelectPage()),
          );
        },
      ),
      _AdminMenuItem(
        icon: Icons.account_circle_outlined,
        title: '마이페이지',
        description: '내 정보 조회와 비밀번호 변경',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyPage()),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 홈'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _AdminHeader(userName: userName, roleLabel: roleLabel);
          }

          return menuItems[index - 1];
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemCount: menuItems.length + 1,
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.userName,
    required this.roleLabel,
  });

  final String userName;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$userName $roleLabel님',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '작업 현장과 출석 데이터를 관리합니다.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  const _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

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
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(description),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap:
            onTap ??
            () {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(content: Text('$title 화면은 다음 단계에서 연결합니다.')),
                );
            },
      ),
    );
  }
}
