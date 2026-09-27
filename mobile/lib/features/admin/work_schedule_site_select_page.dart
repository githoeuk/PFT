import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'work_site.dart';
import 'work_site_service.dart';
import 'work_schedule_list_page.dart';

class WorkScheduleSiteSelectPage extends StatefulWidget {
  const WorkScheduleSiteSelectPage({super.key});

  @override
  State<WorkScheduleSiteSelectPage> createState() =>
      _WorkScheduleSiteSelectPageState();
}

class _WorkScheduleSiteSelectPageState
    extends State<WorkScheduleSiteSelectPage> {
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
      appBar: AppBar(title: const Text('작업 일정 현장 선택')),
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
                children: const [Text('작업 일정을 등록할 현장이 없습니다.')],
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
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(workSite.name),
                    subtitle: Text(workSite.address),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkScheduleListPage(workSite: workSite),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
