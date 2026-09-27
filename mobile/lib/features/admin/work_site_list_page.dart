import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'work_site.dart';
import 'work_site_service.dart';
import 'work_site_form_page.dart';

class WorkSiteListPage extends StatefulWidget {
  const WorkSiteListPage({super.key});

  @override
  State<WorkSiteListPage> createState() => _WorkSiteListPageState();
}

class _WorkSiteListPageState extends State<WorkSiteListPage> {
  final WorkSiteService _workSiteService = WorkSiteService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late Future<List<WorkSite>> _workSitesFuture;

  @override
  void initState() {
    super.initState();
    _workSitesFuture = _workSiteService.findWorkSites();
  }

  Future<void> _reload() async {
    setState(() {
      _workSitesFuture = _workSiteService.findWorkSites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('작업 현장 관리')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<WorkSite>>(
          future: _workSitesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('작업 현장을 불러오지 못했습니다.'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final workSites = snapshot.data ?? [];

            if (workSites.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [Text('등록된 작업 현장이 없습니다.')],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: workSites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final workSite = workSites[index];

                return Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(workSite.name),
                    subtitle: Text(
                      '${workSite.address}\n${workSite.description ?? '-'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'deactivate') {
                          _deactivateWorkSite(workSite);
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
                          builder: (_) =>
                              WorkSiteFormPage(initialWorkSite: workSite),
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
      // 작업 현장 생성
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const WorkSiteFormPage()),
          );

          if (created == true) {
            _reload();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deactivateWorkSite(WorkSite workSite) async {
    final confirmed = await _confirm(
      title: '작업 현장 비활성화',
      content:
          '${workSite.name} 현장을 비활성화할까요?\n\n'
          '이 현장에 연결된 일정, 비콘, 급여 설정 사용에도 영향을 줄 수 있습니다.',
      confirmText: '비활성화',
    );

    if (!confirmed) return;

    try {
      await _workSiteService.deactivateWorkSite(workSite.id);

      if (!mounted) return;
      _showMessage('작업 현장이 비활성화되었습니다.');
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
