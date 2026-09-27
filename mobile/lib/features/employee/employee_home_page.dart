import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../attendance/attendance_service.dart';
import '../auth/auth_service.dart';
import '../attendance/attendance_history_page.dart';
import '../my_page/my_page.dart';
import '../attendance/beacon_scanner_service.dart';

class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key, required this.userName});

  final String userName;

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  final AttendanceService _attendanceService = AttendanceService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  final AuthService _authService = AuthService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  final BeaconScannerService _beaconScannerService =
      const BeaconScannerService();

  bool _isCheckingIn = false;
  bool _isCheckingOut = false;
  String? _lastBeaconMessage;

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _checkIn() async {
    setState(() {
      _isCheckingIn = true;
    });

    try {
      setState(() {
        _lastBeaconMessage = '비콘 검색 중...';
      });

     final beacon = await _beaconScannerService.findNearestBeacon();

     if (!mounted) {
       return;
     }

     setState(() {
       _lastBeaconMessage =
           '감지된 비콘: ${beacon.beaconUuid}\n'
           'major: ${beacon.beaconMajor}, minor: ${beacon.beaconMinor}, RSSI: ${beacon.rssi}';
     });

      await _attendanceService.checkIn(beacon);
      _showMessage('출근 처리되었습니다.');
    } catch (e) {
      setState(() {
        _lastBeaconMessage = '비콘 확인 실패: $e';
      });
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  Future<void> _checkOut() async {
    setState(() {
      _isCheckingOut = true;
    });

    try {
      setState(() {
        _lastBeaconMessage = '비콘 검색 중...';
      });

     final beacon = await _beaconScannerService.findNearestBeacon();

     if (!mounted) {
       return;
     }

     setState(() {
       _lastBeaconMessage =
           '감지된 비콘: ${beacon.beaconUuid}\n'
           'major: ${beacon.beaconMajor}, minor: ${beacon.beaconMinor}, RSSI: ${beacon.rssi}';
     });

      await _attendanceService.checkOut(beacon);
      _showMessage('퇴근 처리되었습니다.');
    } catch (e) {
      setState(() {
        _lastBeaconMessage = '비콘 확인 실패: $e';
      });
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
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
        title: const Text('직원 홈'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: _logout,
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EmployeeHeader(userName: widget.userName),
          const SizedBox(height: 20),
          _AttendanceActionPanel(
            lastBeaconMessage: _lastBeaconMessage,
            onCheckIn: _isCheckingIn ? null : _checkIn,
            onCheckOut: _isCheckingOut ? null : _checkOut,
          ),
          const SizedBox(height: 20),
          _EmployeeMenuItem(
            icon: Icons.history_outlined,
            title: '내 출석 내역',
            description: '출근, 퇴근, 지각, 조퇴 기록 확인',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AttendanceHistoryPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _EmployeeMenuItem(
            icon: Icons.person_outline,
            title: '마이페이지',
            description: '내 정보 확인과 비밀번호 변경',
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const MyPage()));
            },
          ),
        ],
      ),
    );
  }
}

class _EmployeeHeader extends StatelessWidget {
  const _EmployeeHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$userName님',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '비콘 범위 안에서 출근과 퇴근을 기록합니다.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _AttendanceActionPanel extends StatelessWidget {
  const _AttendanceActionPanel({
    required this.onCheckIn,
    required this.onCheckOut,
    required this.lastBeaconMessage,
  });

  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;
  final String? lastBeaconMessage;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '오늘 출석',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCheckIn,
                    icon: const Icon(Icons.login),
                    label: const Text('출근'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCheckOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('퇴근'),
                  ),
                ),
              ],
            ),
            if (lastBeaconMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                lastBeaconMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmployeeMenuItem extends StatelessWidget {
  const _EmployeeMenuItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
