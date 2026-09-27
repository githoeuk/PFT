import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/admin/admin_home_page.dart';
import 'features/employee/employee_home_page.dart';
import 'features/my_page/my_page_service.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/find_login_id_page.dart';
import 'features/auth/password_reset_page.dart';

void main() {
  runApp(const BeaconAttendanceApp());
}

class BeaconAttendanceApp extends StatelessWidget {
  const BeaconAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
    );

    return MaterialApp(
      title: 'PFT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
      routes: {'/login': (_) => const LoginPage()},
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final TokenStorage _tokenStorage = const TokenStorage();
  late final AuthService _authService;
  late final MyPageService _myPageService;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();

    _authService = AuthService(
      apiClient: apiClient,
      tokenStorage: _tokenStorage,
    );

    _myPageService = MyPageService(
      apiClient: apiClient,
      tokenStorage: _tokenStorage,
    );
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final autoLogin = await _tokenStorage.readAutoLogin();
    final refreshToken = await _tokenStorage.readRefreshToken();

    if (!mounted) {
      return;
    }

    if (autoLogin && refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _authService.refreshAccessToken();

        final user = await _myPageService.findMyPage();
        final homePage = _homePageForRole(role: user.role, userName: user.name);

        if (!mounted) {
          return;
        }

        if (homePage != null) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => homePage));
          return;
        }
      } catch (_) {
        await _tokenStorage.clearLoginSession();
      }
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

Widget? _homePageForRole({required String role, required String userName}) {
  if (role == 'SUPER_ADMIN' || role == 'ADMIN') {
    return AdminHomePage(userName: userName, role: role);
  }

  if (role == 'EMPLOYEE') {
    return EmployeeHomePage(userName: userName);
  }

  return null;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TokenStorage _tokenStorage = const TokenStorage();
  late final AuthService _authService;
  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _autoLogin = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(
      apiClient: ApiClient(),
      tokenStorage: _tokenStorage,
    );
    _loadSavedLoginInfo();
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLoginInfo() async {
    final lastLoginId = await _tokenStorage.readLastLoginId();
    final autoLogin = await _tokenStorage.readAutoLogin();

    if (!mounted) {
      return;
    }

    setState(() {
      _loginIdController.text = lastLoginId ?? '';
      _autoLogin = autoLogin;
    });

    if ((lastLoginId ?? '').isNotEmpty) {
      _passwordFocusNode.requestFocus();
    }
  }

  Future<void> _submitLogin() async {
    final loginId = _loginIdController.text.trim();
    final password = _passwordController.text;

    if (loginId.isEmpty || password.isEmpty) {
      _showMessage('아이디와 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.login(
        loginId: loginId,
        password: password,
        autoLogin: _autoLogin,
      );

      if (!mounted) return;

      _openHomePage(role: response.user.role, userName: response.user.name);
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openHomePage({required String role, required String userName}) {
    final homePage = _homePageForRole(role: role, userName: userName);

    if (homePage == null) {
      _showMessage('지원하지 않는 사용자 역할입니다: $role');
      return;
    }

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => homePage));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.sensors_outlined,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PFT',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '작업 현장 출퇴근 기록',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _loginIdController,
                        decoration: const InputDecoration(
                          labelText: '아이디',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? '비밀번호 표시' : '비밀번호 숨김',
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _submitLogin(),
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('자동 로그인'),
                        value: _autoLogin,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _autoLogin = value ?? false;
                                });
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isLoading ? null : _submitLogin,
                        child: Text(_isLoading ? '로그인 중...' : '로그인'),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FindLoginIdPage(),
                                ),
                              );
                            },
                            child: const Text('아이디 찾기'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PasswordResetPage(),
                                ),
                              );
                            },
                            child: const Text('비밀번호 찾기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
