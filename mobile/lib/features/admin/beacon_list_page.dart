import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'beacon.dart';
import 'beacon_service.dart';
import 'work_site.dart';
import 'beacon_form_page.dart';

class BeaconListPage extends StatefulWidget {
  const BeaconListPage({super.key, required this.workSite});

  final WorkSite workSite;

  @override
  State<BeaconListPage> createState() => _BeaconListPageState();
}

class _BeaconListPageState extends State<BeaconListPage> {
  final BeaconService _beaconService = BeaconService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late Future<List<Beacon>> _beaconsFuture;

  @override
  void initState() {
    super.initState();
    _beaconsFuture = _beaconService.findByWorkSite(widget.workSite.id);
  }

  Future<void> _reload() async {
    setState(() {
      _beaconsFuture = _beaconService.findByWorkSite(widget.workSite.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.workSite.name} 비콘')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Beacon>>(
          future: _beaconsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('비콘 목록을 불러오지 못했습니다.'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final beacons = snapshot.data ?? [];

            if (beacons.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [Text('등록된 비콘이 없습니다.')],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: beacons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final beacon = beacons[index];

                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth_searching),
                    title: Text(beacon.name),
                    subtitle: Text(
                      'UUID: ${beacon.uuid}\n'
                      'Major: ${beacon.major} / Minor: ${beacon.minor}\n'
                      'RSSI 기준: ${beacon.rssiThreshold}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'deactivate') {
                          _deactivateBeacon(beacon);
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
                          builder: (_) => BeaconFormPage(
                            workSite: widget.workSite,
                            initialBeacon: beacon,
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
              builder: (_) => BeaconFormPage(workSite: widget.workSite),
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
  // 비콘 비활성화
  Future<void> _deactivateBeacon(Beacon beacon) async {
    final confirmed = await _confirm(
      title: '비콘 비활성화',
      content: '${beacon.name} 비콘을 비활성화할까요?',
      confirmText: '비활성화',
    );

    if (!confirmed) return;

    try {
      await _beaconService.deactivateBeacon(beacon.id);

      if (!mounted) return;
      _showMessage('비콘이 비활성화되었습니다.');
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
