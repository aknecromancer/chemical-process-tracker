import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseWebInitializer {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      // For web platforms, use sqflite_common_ffi
      databaseFactory = databaseFactoryFfi;
    } else {
      // Try to detect desktop platforms
      try {
        if (kIsDesktop) {
          // For desktop platforms, use sqflite_common_ffi
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
        }
      } catch (e) {
        // Fallback: if we can't detect desktop, assume mobile and use default
        // This will work for Android/iOS which use the default sqflite
      }
    }

    _initialized = true;
  }

  static bool get kIsDesktop {
    try {
      // Try to detect if we're on a desktop platform
      return !kIsWeb && (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);
    } catch (e) {
      return false;
    }
  }
}