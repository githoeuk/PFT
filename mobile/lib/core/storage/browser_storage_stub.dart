class BrowserStorage {
  const BrowserStorage();

  bool get isSupported => false;

  Future<void> write({required String key, required String value}) async {}

  Future<String?> read({required String key}) async {
    return null;
  }

  Future<void> delete({required String key}) async {}
}
