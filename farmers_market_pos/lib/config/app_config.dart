class AppConfig {
  AppConfig._();

  // ── API ──────────────────────────────────────────────────────────────────────
  // Change this to your server IP when testing on a physical device
  static const String baseUrl = 'https://13.60.38.149:8000/api';
  // static const String baseUrl = 'http://192.168.1.x/api'; // Physical device

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Hive boxes ────────────────────────────────────────────────────────────────
  static const String offlineQueueBox = 'offline_queue';
  static const String cacheBox        = 'app_cache';
  static const String authBox         = 'auth';

  // ── Cache TTLs ────────────────────────────────────────────────────────────────
  static const Duration productCacheTtl  = Duration(hours: 6);
  static const Duration categoryCache    = Duration(hours: 12);

  // ── Business defaults ─────────────────────────────────────────────────────────
  static const double defaultInterestRate     = 0.30;
  static const double defaultCommodityRate    = 1000.0;
}
