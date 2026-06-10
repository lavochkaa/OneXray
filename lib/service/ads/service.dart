class AdsService {
  static final AdsService _singleton = AdsService._internal();
  factory AdsService() => _singleton;
  AdsService._internal();

  Future<void> init() async {}
  void dispose() {}
}
