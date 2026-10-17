import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String tokenKey = 'access_token';

  /// Override at run time:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
  /// For a physical Android device, use your laptop's LAN IP or enable ADB reverse:
  /// adb reverse tcp:8000 tcp:8000
  static List<String> get baseUrls {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return [fromEnv.trim()];

    if (kIsWeb) {
      return ['http://localhost:8000/api', 'http://127.0.0.1:8000/api'];
    }

    if (Platform.isAndroid) {
      return [
        'http://10.0.2.2:8000/api',
        'http://127.0.0.1:8000/api',
        'http://localhost:8000/api',
      ];
    }

    return ['http://127.0.0.1:8000/api', 'http://localhost:8000/api'];
  }

  static String get baseUrl => baseUrls.first;
}
