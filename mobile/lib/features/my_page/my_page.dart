import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'my_page_info.dart';
import 'my_page_service.dart';
import 'my_page_edit_page.dart';
import 'password_change_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final MyPageService _myPageService = MyPageService(
    apiClient: ApiClient(),
    tokenStorage: const TokenStorage(),
  );

  late Future<MyPageInfo> _myPageFuture;

  @override
  void initState() {
    super.initState();
    _myPageFuture = _myPageService.findMyPage();
  }

  Future<void> _reload() async {
    setState(() {
      _myPageFuture = _myPageService.findMyPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<MyPageInfo>(
          future: _myPageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('내 정보를 불러오지 못했습니다.'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                ],
              );
            }

            final info = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  title: const Text('이름'),
                  subtitle: Text(info.name),
                ),
                ListTile(
                  title: const Text('아이디'),
                  subtitle: Text(info.loginId),
                ),
                ListTile(
                  title: const Text('전화번호'),
                  subtitle: Text(info.phone ?? '-'),
                ),
                ListTile(
                  title: const Text('역할'),
                  subtitle: Text(info.roleLabel),
                ),
                ListTile(
                  title: const Text('계정 상태'),
                  subtitle: Text(info.active ? '사용 중' : '비활성화'),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => MyPageEditPage(initialInfo: info),
                      ),
                    );

                    if (changed == true) {
                      _reload();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('내 정보 수정'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PasswordChangePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('비밀번호 변경'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}