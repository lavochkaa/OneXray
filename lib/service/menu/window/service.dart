final class WindowService {
  static final WindowService _singleton = WindowService._internal();
  factory WindowService() => _singleton;
  WindowService._internal();

  Future<void> asyncInit() async {}
  void dispose() {}
}
