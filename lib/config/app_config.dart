// App-wide backend configuration.
// (The theme lives in theme.dart; this file used to hold a duplicate copy of it.)

import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// Shareloop Laravel API (backend/). Override at build time:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
  /// Defaults: web / desktop → localhost, Android emulator → 10.0.2.2 (the
  /// host computer). A real phone needs your computer's LAN IP.
  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  /// Max photos per item (also enforced by the API).
  static const int maxItemImages = 5;
}
