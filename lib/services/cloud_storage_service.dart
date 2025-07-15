import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/configurable_defaults.dart';
import '../models/production_batch.dart';
import 'supabase_service.dart';
import 'mobile_storage_service.dart';

/// Cloud storage service with offline-first approach
/// This service handles synchronization between local storage and cloud (Supabase)
class CloudStorageService {
  static const String _pendingSyncKey = 'pending_sync_operations';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncStatusKey = 'sync_status';
  
  static CloudStorageService? _instance;
  
  // Private constructor
  CloudStorageService._();
  
  /// Get singleton instance
  static CloudStorageService get instance {
    _instance ??= CloudStorageService._();
    return _instance!;
  }
  
  /// Initialize cloud storage service
  static Future<void> initialize() async {
    try {
      // Initialize Supabase if not already initialized
      if (!SupabaseService.isInitialized) {
        await SupabaseService.initialize();
      }
      
      // Try to sync on startup if online
      if (await instance.isOnline()) {
        await instance.syncAll();
      }
    } catch (e) {
      print('Cloud storage initialization failed: $e');
      // Continue with offline mode
    }
  }
  
  /// Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  /// Check if cloud service is available
  Future<bool> isCloudAvailable() async {
    if (!await isOnline()) return false;
    
    try {
      if (!SupabaseService.isInitialized) return false;
      return await SupabaseService.instance.healthCheck();
    } catch (e) {
      return false;
    }
  }
  
  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_syncStatusKey);
      
      if (statusJson != null) {
        return jsonDecode(statusJson);
      }
      
      return {
        'lastSync': null,
        'pendingOperations': 0,
        'isOnline': await isOnline(),
        'cloudAvailable': await isCloudAvailable(),
      };
    } catch (e) {
      print('Error getting sync status: $e');
      return {
        'lastSync': null,
        'pendingOperations': 0,
        'isOnline': false,
        'cloudAvailable': false,
      };
    }
  }
  
  /// Update sync status
  Future<void> updateSyncStatus(Map<String, dynamic> status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_syncStatusKey, jsonEncode(status));
    } catch (e) {
      print('Error updating sync status: $e');
    }
  }
  
  /// Get defaults with offline-first approach
  Future<ConfigurableDefaults?> getDefaults() async {
    try {
      // Always try local first
      final localDefaults = await MobileStorageService.getDefaults();
      
      // If online, try to sync with cloud
      if (await isCloudAvailable()) {
        try {
          final cloudDefaults = await SupabaseService.instance.getDefaults();
          
          // If cloud has newer data, update local and return cloud data
          if (cloudDefaults != null) {
            await MobileStorageService.saveDefaults(cloudDefaults);
            return cloudDefaults;
          }
        } catch (e) {
          print('Error fetching defaults from cloud: $e');
          // Fall back to local data
        }
      }
      
      return localDefaults;
    } catch (e) {
      print('Error getting defaults: $e');
      return null;
    }
  }
  
  /// Save defaults with offline-first approach
  Future<void> saveDefaults(ConfigurableDefaults defaults) async {
    try {
      // Always save to local first
      await MobileStorageService.saveDefaults(defaults);
      
      // If online, try to sync with cloud
      if (await isCloudAvailable()) {
        try {
          await SupabaseService.instance.saveDefaults(defaults);
        } catch (e) {
          print('Error saving defaults to cloud: $e');
          // Add to pending sync operations
          await _addPendingSyncOperation('saveDefaults', defaults.toJson());
        }
      } else {
        // Add to pending sync operations
        await _addPendingSyncOperation('saveDefaults', defaults.toJson());
      }
    } catch (e) {
      print('Error saving defaults: $e');
      rethrow;
    }
  }
  
  /// Get all batches with offline-first approach
  Future<List<ProductionBatch>> getAllBatches() async {
    try {
      // Always try local first
      final localBatches = await MobileStorageService.getAllBatches();
      
      // If online, try to sync with cloud
      if (await isCloudAvailable()) {
        try {
          final cloudBatches = await SupabaseService.instance.getAllBatches();
          
          // Merge local and cloud data (cloud takes precedence)
          final mergedBatches = await _mergeBatches(localBatches, cloudBatches);
          
          // Update local storage with merged data
          await _updateLocalBatches(mergedBatches);
          
          return mergedBatches;
        } catch (e) {
          print('Error fetching batches from cloud: $e');
          // Fall back to local data
        }
      }
      
      return localBatches;
    } catch (e) {
      print('Error getting batches: $e');
      return [];
    }
  }
  
  /// Get batch by date with offline-first approach
  Future<ProductionBatch?> getBatchByDate(DateTime date) async {
    try {
      // Always try local first
      final localBatch = await MobileStorageService.getBatchByDate(date);
      
      // If online, try to sync with cloud
      if (await isCloudAvailable()) {
        try {
          final cloudBatch = await SupabaseService.instance.getBatchByDate(date);
          
          // If cloud has data, update local and return cloud data
          if (cloudBatch != null) {
            await MobileStorageService.saveBatch(cloudBatch);
            return cloudBatch;
          }
        } catch (e) {
          print('Error fetching batch from cloud: $e');
          // Fall back to local data
        }
      }
      
      return localBatch;
    } catch (e) {
      print('Error getting batch by date: $e');
      return null;
    }
  }
  
  /// Save batch with offline-first approach
  Future<void> saveBatch(ProductionBatch batch) async {
    try {
      // Always save to local first
      await MobileStorageService.saveBatch(batch);
      
      // If online, try to sync with cloud
      if (await isCloudAvailable()) {
        try {
          await SupabaseService.instance.saveBatch(batch);
        } catch (e) {
          print('Error saving batch to cloud: $e');
          // Add to pending sync operations
          await _addPendingSyncOperation('saveBatch', batch.toJson());
        }
      } else {
        // Add to pending sync operations
        await _addPendingSyncOperation('saveBatch', batch.toJson());
      }
    } catch (e) {
      print('Error saving batch: $e');
      rethrow;
    }
  }
  
  /// Update batch with offline-first approach
  Future<void> updateBatch(ProductionBatch batch) async {
    await saveBatch(batch); // Same operation for our implementation
  }
  
  /// Delete batch with offline-first approach
  Future<void> deleteBatch(DateTime date) async {
    try {
      // Always delete from local first
      await MobileStorageService.deleteBatch(date);
      
      // If online, try to sync with cloud
      if (await isCloudAvailable()) {
        try {
          await SupabaseService.instance.deleteBatch(date);
        } catch (e) {
          print('Error deleting batch from cloud: $e');
          // Add to pending sync operations
          await _addPendingSyncOperation('deleteBatch', {'date': date.toIso8601String()});
        }
      } else {
        // Add to pending sync operations
        await _addPendingSyncOperation('deleteBatch', {'date': date.toIso8601String()});
      }
    } catch (e) {
      print('Error deleting batch: $e');
      rethrow;
    }
  }
  
  /// Sync all data with cloud
  Future<void> syncAll() async {
    try {
      if (!await isCloudAvailable()) {
        print('Cloud not available, skipping sync');
        return;
      }
      
      // Process pending sync operations
      await _processPendingSyncOperations();
      
      // Update sync status
      await updateSyncStatus({
        'lastSync': DateTime.now().toIso8601String(),
        'pendingOperations': 0,
        'isOnline': await isOnline(),
        'cloudAvailable': await isCloudAvailable(),
      });
      
      print('Sync completed successfully');
    } catch (e) {
      print('Error during sync: $e');
      rethrow;
    }
  }
  
  /// Add pending sync operation
  Future<void> _addPendingSyncOperation(String operation, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsJson = prefs.getString(_pendingSyncKey) ?? '[]';
      final pendingOps = List<Map<String, dynamic>>.from(jsonDecode(pendingOpsJson));
      
      pendingOps.add({
        'operation': operation,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await prefs.setString(_pendingSyncKey, jsonEncode(pendingOps));
    } catch (e) {
      print('Error adding pending sync operation: $e');
    }
  }
  
  /// Process pending sync operations
  Future<void> _processPendingSyncOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsJson = prefs.getString(_pendingSyncKey) ?? '[]';
      final pendingOps = List<Map<String, dynamic>>.from(jsonDecode(pendingOpsJson));
      
      for (final op in pendingOps) {
        try {
          await _executeSyncOperation(op['operation'], op['data']);
        } catch (e) {
          print('Error executing sync operation ${op['operation']}: $e');
          // Continue with other operations
        }
      }
      
      // Clear pending operations
      await prefs.setString(_pendingSyncKey, '[]');
    } catch (e) {
      print('Error processing pending sync operations: $e');
    }
  }
  
  /// Execute sync operation
  Future<void> _executeSyncOperation(String operation, Map<String, dynamic> data) async {
    switch (operation) {
      case 'saveDefaults':
        final defaults = ConfigurableDefaults.fromJson(data);
        await SupabaseService.instance.saveDefaults(defaults);
        break;
      case 'saveBatch':
        final batch = ProductionBatch.fromJson(data);
        await SupabaseService.instance.saveBatch(batch);
        break;
      case 'deleteBatch':
        final date = DateTime.parse(data['date']);
        await SupabaseService.instance.deleteBatch(date);
        break;
      default:
        print('Unknown sync operation: $operation');
    }
  }
  
  /// Merge local and cloud batches
  Future<List<ProductionBatch>> _mergeBatches(List<ProductionBatch> localBatches, List<ProductionBatch> cloudBatches) async {
    final Map<String, ProductionBatch> mergedMap = {};
    
    // Add local batches
    for (final batch in localBatches) {
      final key = batch.date.toIso8601String().split('T')[0];
      mergedMap[key] = batch;
    }
    
    // Add cloud batches (overwrite local if exists)
    for (final batch in cloudBatches) {
      final key = batch.date.toIso8601String().split('T')[0];
      mergedMap[key] = batch;
    }
    
    // Convert back to list and sort by date
    final result = mergedMap.values.toList();
    result.sort((a, b) => b.date.compareTo(a.date));
    
    return result;
  }
  
  /// Update local batches with merged data
  Future<void> _updateLocalBatches(List<ProductionBatch> batches) async {
    try {
      // Clear local storage
      await MobileStorageService.clearAllData();
      
      // Save merged batches
      for (final batch in batches) {
        await MobileStorageService.saveBatch(batch);
      }
    } catch (e) {
      print('Error updating local batches: $e');
    }
  }
  
  /// Clear all data
  Future<void> clearAllData() async {
    try {
      // Clear local data
      await MobileStorageService.clearAllData();
      
      // Clear cloud data if available
      if (await isCloudAvailable()) {
        await SupabaseService.instance.clearAllData();
      }
      
      // Clear pending sync operations
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingSyncKey);
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_syncStatusKey);
    } catch (e) {
      print('Error clearing all data: $e');
      rethrow;
    }
  }
  
  /// Get pending sync operations count
  Future<int> getPendingSyncOperationsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsJson = prefs.getString(_pendingSyncKey) ?? '[]';
      final pendingOps = List<Map<String, dynamic>>.from(jsonDecode(pendingOpsJson));
      return pendingOps.length;
    } catch (e) {
      print('Error getting pending sync operations count: $e');
      return 0;
    }
  }
}