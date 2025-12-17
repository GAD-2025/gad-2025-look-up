import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

String getBaseUrl() {
  if (kIsWeb) {
    // Running on the web
    return 'http://localhost:3000';
  } else if (Platform.isAndroid) {
    // Running on Android (emulator)
    return 'http://10.0.2.2:3000';
  } else if (Platform.isIOS) {
    // Running on iOS (simulator)
    return 'http://localhost:3000';
  } else {
    // Default for other platforms
    return 'http://localhost:3000';
  }
}
