import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'pay_setting.dart';
import 'pay_setting_service.dart';
import 'work_site.dart';
import 'pay_setting_form_page.dart';

class PaySettingListPage extends StatefulWidget {
  const PaySettingListPage({
    super.key,
    required this.workSite,
  });

  final WorkSite workSite;

  @override
  State<PaySettingListPage> createState() => _PaySettingListPageState();
}

class _PaySettingListPageState extends State<PaySettingListPage> {
  final PaySettingService _paySettingService = PaySettingService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late Future<List<PaySetting>> _paySettingsFuture;

  @override
  void initState() {
    super.initState();
    _paySettingsFuture = _paySettingService.findByWorkSite(widget.workSite.id);
  }

  Future<void> _reload() async {
    setState(() {
      _paySettingsFuture = _paySettingService.findByWorkSite(
        widget.workSite.id,
      );
    });
  }

  // 급여 비활성화
  Future<void> _deactivatePaySetting(PaySetting paySetting) async {
    final confirmed = await _confirm(
      title: '급여 설정 비활성화',
      content: '${paySetting.employeeName} 직원의 급여 설정을 비활성화할까요?',
      confirmText: '비활성화',
    );

    if (!confirmed) return;

    try {
      await _paySettingService.deactivatePaySetting(paySetting.id);

      if (!mounted) return;
      _showMessage('급여 설정이 비활성화되었습니다.');
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
      appBar: AppBar(
        title: Text('${widget.workSite.name} 급여 설정'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<PaySetting>>(
          future: _paySettingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('급여 설정을 불러오지 못했습니다.'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final paySettings = snapshot.data ?? [];

            if (paySettings.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Text('등록된 급여 설정이 없습니다.'),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: paySettings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final paySetting = paySettings[index];

                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: Text(paySetting.employeeName),
                    subtitle: Text(
                      '일급: ${paySetting.dailyWageLabel}\n'
                      '세율: ${paySetting.taxRateLabel}\n'
                      '세금: ${paySetting.taxAmountLabel}\n'
                      '세후 일급: ${paySetting.netDailyWageLabel}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'deactivate') {
                          _deactivatePaySetting(paySetting);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Text('비활성화'),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => PaySettingFormPage(
                            workSite: widget.workSite,
                            initialPaySetting: paySetting,
                          ),
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
              builder: (_) => PaySettingFormPage(workSite: widget.workSite),
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
}
