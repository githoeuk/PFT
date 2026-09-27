// Web HTTP 테스트 전용 fallback 저장소입니다.
// 운영 Web은 HTTPS에서 flutter_secure_storage를 사용하는 것이 맞습니다.
import 'dart:html' as html;

class BrowserStorage {
  const BrowserStorage();

  bool get isSupported => true;

  Future<void> write({required String key, required String value}) async {
    html.window.localStorage[key] = value;
  }

  Future<String?> read({required String key}) async {
    return html.window.localStorage[key];
  }

  Future<void> delete({required String key}) async {
    html.window.localStorage.remove(key);
  }
}
