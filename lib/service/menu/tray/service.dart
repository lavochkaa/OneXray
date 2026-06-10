final class TrayService {
  static final TrayService _singleton = TrayService._internal();
  factory TrayService() => _singleton;
  TrayService._internal();

  void init() {}
  void dispose() {}
  Future<void> refreshTrayManager() async {}
}
