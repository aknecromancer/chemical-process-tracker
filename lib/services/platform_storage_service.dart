import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/configurable_defaults.dart';
import '../models/production_batch.dart';

// Platform-specific imports with conditional loading
import 'mobile_storage_service.dart' as mobile;
// Conditional import for web storage
import 'mobile_storage_service.dart' as web if (dart.library.html) 'web_storage_service.dart';

/// Platform-adaptive storage service that works on both web and mobile
class PlatformStorageService {
  static const String _defaultsKey = 'chemical_tracker_defaults';
  static const String _batchesKey = 'chemical_tracker_batches';

  /// Get defaults from platform-specific storage
  static Future<ConfigurableDefaults?> getDefaults() async {
    if (kIsWeb) {
      // Use mobile storage as fallback for now
      return mobile.MobileStorageService.getDefaults();
    } else {
      return mobile.MobileStorageService.getDefaults();
    }
  }

  /// Save defaults to platform-specific storage
  static Future<void> saveDefaults(ConfigurableDefaults defaults) async {
    if (kIsWeb) {
      // Use mobile storage as fallback for now
      return mobile.MobileStorageService.saveDefaults(defaults);
    } else {
      return mobile.MobileStorageService.saveDefaults(defaults);
    }
  }

  /// Get all batches from platform-specific storage
  static Future<List<ProductionBatch>> getAllBatches() async {
    if (kIsWeb) {
      // Use mobile storage as fallback for now
      return mobile.MobileStorageService.getAllBatches();
    } else {
      return mobile.MobileStorageService.getAllBatches();
    }
  }

  /// Save batch to platform-specific storage
  static Future<void> saveBatch(ProductionBatch batch) async {
    if (kIsWeb) {
      // Use mobile storage as fallback for now
      return mobile.MobileStorageService.saveBatch(batch);
    } else {
      return mobile.MobileStorageService.saveBatch(batch);
    }
  }

  /// Get batch by date from platform-specific storage
  static Future<ProductionBatch?> getBatchByDate(DateTime date) async {
    if (kIsWeb) {
      // Use mobile storage as fallback for now
      return mobile.MobileStorageService.getBatchByDate(date);
    } else {
      return mobile.MobileStorageService.getBatchByDate(date);
    }
  }

  /// Delete batch from platform-specific storage
  static Future<void> deleteBatch(DateTime date) async {
    if (kIsWeb) {
      // Use mobile storage as fallback for now
      return mobile.MobileStorageService.deleteBatch(date);
    } else {
      return mobile.MobileStorageService.deleteBatch(date);
    }
  }

  /// Update existing batch in platform-specific storage
  static Future<void> updateBatch(ProductionBatch batch) async {
    if (kIsWeb) {
      // Use mobile storage as fallback for now
      return mobile.MobileStorageService.updateBatch(batch);
    } else {
      return mobile.MobileStorageService.updateBatch(batch);
    }
  }

  /// Clear all data from platform-specific storage
  static Future<void> clearAllData() async {
    if (kIsWeb) {
      // Use mobile storage as fallback for now
      return mobile.MobileStorageService.clearAllData();
    } else {
      return mobile.MobileStorageService.clearAllData();
    }
  }
}