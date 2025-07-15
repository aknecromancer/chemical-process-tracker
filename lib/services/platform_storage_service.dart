import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/configurable_defaults.dart';
import '../models/production_batch.dart';

// Platform-specific imports with conditional loading
import 'mobile_storage_service.dart' as mobile;
import 'cloud_storage_service.dart';
// Conditional import for web storage
import 'mobile_storage_service.dart' as web if (dart.library.html) 'web_storage_service.dart';

/// Platform-adaptive storage service that works on both web and mobile
/// Now includes cloud synchronization with offline-first approach
class PlatformStorageService {
  static const String _defaultsKey = 'chemical_tracker_defaults';
  static const String _batchesKey = 'chemical_tracker_batches';
  
  /// Initialize platform storage with cloud sync
  static Future<void> initialize() async {
    try {
      await CloudStorageService.initialize();
    } catch (e) {
      print('Cloud storage initialization failed, continuing with local storage: $e');
    }
  }

  /// Get defaults from platform-specific storage with cloud sync
  static Future<ConfigurableDefaults?> getDefaults() async {
    try {
      // Use cloud storage service for both web and mobile
      return await CloudStorageService.instance.getDefaults();
    } catch (e) {
      print('Error getting defaults from cloud storage, falling back to local: $e');
      // Fallback to local storage
      if (kIsWeb) {
        return mobile.MobileStorageService.getDefaults();
      } else {
        return mobile.MobileStorageService.getDefaults();
      }
    }
  }

  /// Save defaults to platform-specific storage with cloud sync
  static Future<void> saveDefaults(ConfigurableDefaults defaults) async {
    try {
      // Use cloud storage service for both web and mobile
      return await CloudStorageService.instance.saveDefaults(defaults);
    } catch (e) {
      print('Error saving defaults to cloud storage, falling back to local: $e');
      // Fallback to local storage
      if (kIsWeb) {
        return mobile.MobileStorageService.saveDefaults(defaults);
      } else {
        return mobile.MobileStorageService.saveDefaults(defaults);
      }
    }
  }

  /// Get all batches from platform-specific storage with cloud sync
  static Future<List<ProductionBatch>> getAllBatches() async {
    try {
      // Use cloud storage service for both web and mobile
      return await CloudStorageService.instance.getAllBatches();
    } catch (e) {
      print('Error getting batches from cloud storage, falling back to local: $e');
      // Fallback to local storage
      if (kIsWeb) {
        return mobile.MobileStorageService.getAllBatches();
      } else {
        return mobile.MobileStorageService.getAllBatches();
      }
    }
  }

  /// Save batch to platform-specific storage with cloud sync
  static Future<void> saveBatch(ProductionBatch batch) async {
    try {
      // Use cloud storage service for both web and mobile
      return await CloudStorageService.instance.saveBatch(batch);
    } catch (e) {
      print('Error saving batch to cloud storage, falling back to local: $e');
      // Fallback to local storage
      if (kIsWeb) {
        return mobile.MobileStorageService.saveBatch(batch);
      } else {
        return mobile.MobileStorageService.saveBatch(batch);
      }
    }
  }

  /// Get batch by date from platform-specific storage with cloud sync
  static Future<ProductionBatch?> getBatchByDate(DateTime date) async {
    try {
      // Use cloud storage service for both web and mobile
      return await CloudStorageService.instance.getBatchByDate(date);
    } catch (e) {
      print('Error getting batch by date from cloud storage, falling back to local: $e');
      // Fallback to local storage
      if (kIsWeb) {
        return mobile.MobileStorageService.getBatchByDate(date);
      } else {
        return mobile.MobileStorageService.getBatchByDate(date);
      }
    }
  }

  /// Delete batch from platform-specific storage with cloud sync
  static Future<void> deleteBatch(DateTime date) async {
    try {
      // Use cloud storage service for both web and mobile
      return await CloudStorageService.instance.deleteBatch(date);
    } catch (e) {
      print('Error deleting batch from cloud storage, falling back to local: $e');
      // Fallback to local storage
      if (kIsWeb) {
        return mobile.MobileStorageService.deleteBatch(date);
      } else {
        return mobile.MobileStorageService.deleteBatch(date);
      }
    }
  }

  /// Update existing batch in platform-specific storage with cloud sync
  static Future<void> updateBatch(ProductionBatch batch) async {
    try {
      // Use cloud storage service for both web and mobile
      return await CloudStorageService.instance.updateBatch(batch);
    } catch (e) {
      print('Error updating batch in cloud storage, falling back to local: $e');
      // Fallback to local storage
      if (kIsWeb) {
        return mobile.MobileStorageService.updateBatch(batch);
      } else {
        return mobile.MobileStorageService.updateBatch(batch);
      }
    }
  }

  /// Clear all data from platform-specific storage with cloud sync
  static Future<void> clearAllData() async {
    try {
      // Use cloud storage service for both web and mobile
      return await CloudStorageService.instance.clearAllData();
    } catch (e) {
      print('Error clearing data from cloud storage, falling back to local: $e');
      // Fallback to local storage
      if (kIsWeb) {
        return mobile.MobileStorageService.clearAllData();
      } else {
        return mobile.MobileStorageService.clearAllData();
      }
    }
  }

  /// Get sync status
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      return await CloudStorageService.instance.getSyncStatus();
    } catch (e) {
      print('Error getting sync status: $e');
      return {
        'lastSync': null,
        'pendingOperations': 0,
        'isOnline': false,
        'cloudAvailable': false,
        'error': e.toString(),
      };
    }
  }

  /// Force sync with cloud
  static Future<void> syncWithCloud() async {
    try {
      await CloudStorageService.instance.syncAll();
    } catch (e) {
      print('Error syncing with cloud: $e');
      rethrow;
    }
  }

  /// Check if cloud is available
  static Future<bool> isCloudAvailable() async {
    try {
      return await CloudStorageService.instance.isCloudAvailable();
    } catch (e) {
      print('Error checking cloud availability: $e');
      return false;
    }
  }

  /// Get pending sync operations count
  static Future<int> getPendingSyncOperationsCount() async {
    try {
      return await CloudStorageService.instance.getPendingSyncOperationsCount();
    } catch (e) {
      print('Error getting pending sync operations count: $e');
      return 0;
    }
  }
}