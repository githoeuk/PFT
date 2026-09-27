import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'browser_storage.dart';

class TokenStorage {
  const TokenStorage({
    FlutterSecureStorage? secureStorage,
    BrowserStorage? browserStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _browserStorage = browserStorage ?? const BrowserStorage();

  static const String _accessTokenKey = 'accessToken';
  static const String _lastLoginIdKey = 'lastLoginId';
  static const String _autoLoginKey = 'autoLogin';
  static const String _refreshTokenKey = 'refreshToken';

  final FlutterSecureStorage _secureStorage;
  final BrowserStorage _browserStorage;

  Future<void> saveAccessToken(String accessToken) {
    return _write(key: _accessTokenKey, value: accessToken);
  }

  Future<void> saveRefreshToken(String refreshToken) {
    return _write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> readRefreshToken() {
    return _read(key: _refreshTokenKey);
  }

  Future<void> clearRefreshToken() {
    return _delete(key: _refreshTokenKey);
  }

  Future<String?> readAccessToken() {
    return _read(key: _accessTokenKey);
  }

  Future<void> clearAccessToken() {
    return _delete(key: _accessTokenKey);
  }

  Future<void> saveLastLoginId(String loginId) {
    return _write(key: _lastLoginIdKey, value: loginId);
  }

  Future<String?> readLastLoginId() {
    return _read(key: _lastLoginIdKey);
  }

  Future<void> saveAutoLogin(bool autoLogin) {
    return _write(key: _autoLoginKey, value: autoLogin.toString());
  }

  Future<bool> readAutoLogin() async {
    final value = await _read(key: _autoLoginKey);
    return value == 'true';
  }

  Future<void> clearLoginSession() async {
    await clearAccessToken();
    await clearRefreshToken();
    await saveAutoLogin(false);
  }

  Future<void> _write({required String key, required String value}) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (error) {
      if (!_canUseBrowserFallback(error)) {
        rethrow;
      }
      await _browserStorage.write(key: key, value: value);
    }
  }

  Future<String?> _read({required String key}) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null || !_browserStorage.isSupported) {
        return value;
      }

      return _browserStorage.read(key: key);
    } catch (error) {
      if (!_canUseBrowserFallback(error)) {
        rethrow;
      }
      return _browserStorage.read(key: key);
    }
  }

  Future<void> _delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
      if (_browserStorage.isSupported) {
        await _browserStorage.delete(key: key);
      }
    } catch (error) {
      if (!_canUseBrowserFallback(error)) {
        rethrow;
      }
      await _browserStorage.delete(key: key);
    }
  }

  bool _canUseBrowserFallback(Object error) {
    if (!_browserStorage.isSupported) {
      return false;
    }

    return error.toString().contains('FlutterSecureStorageWeb');
  }
}
