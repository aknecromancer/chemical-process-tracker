import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/configurable_defaults.dart';
import '../models/production_batch.dart';

/// Mobile storage service using SharedPreferences for persistent data storage
class MobileStorageService {
  static const String _defaultsKey = 'chemical_tracker_defaults';
  static const String _batchesKey = 'chemical_tracker_batches';

  /// Get defaults from SharedPreferences
  static Future<ConfigurableDefaults?> getDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_defaultsKey);
      if (data == null) return null;

      final json = jsonDecode(data) as Map<String, dynamic>;
      return ConfigurableDefaults.fromJson(json);
    } catch (e) {
      print('Error loading defaults: $e');
      return null;
    }
  }

  /// Save defaults to SharedPreferences
  static Future<void> saveDefaults(ConfigurableDefaults defaults) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = defaults.toJson();
      await prefs.setString(_defaultsKey, jsonEncode(json));
    } catch (e) {
      print('Error saving defaults: $e');
      rethrow;
    }
  }

  /// Get all batches from SharedPreferences
  static Future<List<ProductionBatch>> getAllBatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_batchesKey);
      if (data == null) return [];

      final jsonList = jsonDecode(data) as List<dynamic>;
      return jsonList
          .map((json) => ProductionBatch.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading batches: $e');
      return [];
    }
  }

  /// Save batch to SharedPreferences
  static Future<void> saveBatch(ProductionBatch batch) async {
    try {
      final batches = await getAllBatches();
      
      // Check if batch already exists
      final existingIndex = batches.indexWhere((b) => 
          b.date.year == batch.date.year &&
          b.date.month == batch.date.month &&
          b.date.day == batch.date.day);
      
      if (existingIndex != -1) {
        batches[existingIndex] = batch;
      } else {
        batches.add(batch);
      }
      
      // Sort by date (newest first)
      batches.sort((a, b) => b.date.compareTo(a.date));
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = batches.map((batch) => batch.toJson()).toList();
      await prefs.setString(_batchesKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving batch: $e');
      rethrow;
    }
  }

  /// Get batch by date from SharedPreferences
  static Future<ProductionBatch?> getBatchByDate(DateTime date) async {
    try {
      final batches = await getAllBatches();
      return batches.firstWhere(
        (batch) => 
            batch.date.year == date.year &&
            batch.date.month == date.month &&
            batch.date.day == date.day,
        orElse: () => throw StateError('No batch found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Delete batch from SharedPreferences
  static Future<void> deleteBatch(DateTime date) async {
    try {
      final batches = await getAllBatches();
      batches.removeWhere((batch) => 
          batch.date.year == date.year &&
          batch.date.month == date.month &&
          batch.date.day == date.day);
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = batches.map((batch) => batch.toJson()).toList();
      await prefs.setString(_batchesKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error deleting batch: $e');
      rethrow;
    }
  }

  /// Update existing batch in SharedPreferences
  static Future<void> updateBatch(ProductionBatch batch) async {
    // For SharedPreferences, update is the same as save
    await saveBatch(batch);
  }

  /// Clear all data from SharedPreferences
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_defaultsKey);
      await prefs.remove(_batchesKey);
    } catch (e) {
      print('Error clearing data: $e');
      rethrow;
    }
  }
}