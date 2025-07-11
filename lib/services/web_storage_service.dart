import 'dart:html' as html;
import 'dart:convert';
import '../models/configurable_defaults.dart';
import '../models/production_batch.dart';

class WebStorageService {
  static const String _defaultsKey = 'chemical_tracker_defaults';
  static const String _batchesKey = 'chemical_tracker_batches';
  
  // Configurable Defaults
  static Future<ConfigurableDefaults> getDefaults() async {
    try {
      final data = html.window.localStorage[_defaultsKey];
      if (data != null) {
        final Map<String, dynamic> json = jsonDecode(data);
        return ConfigurableDefaults.fromMap(json);
      }
    } catch (e) {
      print('Error loading defaults: $e');
    }
    
    // Return default values if not found or error
    return ConfigurableDefaults();
  }
  
  static Future<void> saveDefaults(ConfigurableDefaults defaults) async {
    try {
      final json = defaults.toMap();
      html.window.localStorage[_defaultsKey] = jsonEncode(json);
    } catch (e) {
      print('Error saving defaults: $e');
      throw Exception('Failed to save defaults: $e');
    }
  }
  
  // Production Batches
  static Future<List<ProductionBatch>> getAllBatches() async {
    try {
      final data = html.window.localStorage[_batchesKey];
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        return jsonList.map((json) => ProductionBatch.fromMap(json)).toList();
      }
    } catch (e) {
      print('Error loading batches: $e');
    }
    return [];
  }
  
  static Future<ProductionBatch?> getBatchByDate(DateTime date) async {
    try {
      final batches = await getAllBatches();
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final matchingBatches = batches.where((batch) {
        final batchDateString = '${batch.date.year}-${batch.date.month.toString().padLeft(2, '0')}-${batch.date.day.toString().padLeft(2, '0')}';
        return batchDateString == dateString;
      }).toList();
      
      return matchingBatches.isNotEmpty ? matchingBatches.first : null;
    } catch (e) {
      print('Error getting batch by date: $e');
    }
    return null;
  }
  
  static Future<void> saveBatch(ProductionBatch batch) async {
    try {
      final batches = await getAllBatches();
      
      // Remove existing batch for the same date
      batches.removeWhere((b) {
        final batchDate = '${b.date.year}-${b.date.month.toString().padLeft(2, '0')}-${b.date.day.toString().padLeft(2, '0')}';
        final newDate = '${batch.date.year}-${batch.date.month.toString().padLeft(2, '0')}-${batch.date.day.toString().padLeft(2, '0')}';
        return batchDate == newDate;
      });
      
      // Add new batch
      batches.add(batch);
      
      // Sort by date (newest first)
      batches.sort((a, b) => b.date.compareTo(a.date));
      
      // Save to localStorage
      final jsonList = batches.map((b) => b.toMap()).toList();
      html.window.localStorage[_batchesKey] = jsonEncode(jsonList);
    } catch (e) {
      print('Error saving batch: $e');
      throw Exception('Failed to save batch: $e');
    }
  }
  
  static Future<void> deleteBatch(String batchId) async {
    try {
      final batches = await getAllBatches();
      batches.removeWhere((b) => b.id == batchId);
      
      final jsonList = batches.map((b) => b.toMap()).toList();
      html.window.localStorage[_batchesKey] = jsonEncode(jsonList);
    } catch (e) {
      print('Error deleting batch: $e');
      throw Exception('Failed to delete batch: $e');
    }
  }
  
  static Future<ProductionBatch> createBatch(DateTime date) async {
    try {
      final batch = ProductionBatch(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: date,
        materials: [],
        totalExpenses: 0,
        totalIncome: 0,
        netPnL: 0,
        pdEfficiency: 0,
        status: BatchStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await saveBatch(batch);
      return batch;
    } catch (e) {
      print('Error creating batch: $e');
      throw Exception('Failed to create batch: $e');
    }
  }
  
  // Export functionality
  static Future<String> exportData() async {
    try {
      final defaults = await getDefaults();
      final batches = await getAllBatches();
      
      final exportData = {
        'defaults': defaults.toMap(),
        'batches': batches.map((b) => b.toMap()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }
  
  static Future<void> importData(String jsonData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      
      if (data['defaults'] != null) {
        final defaults = ConfigurableDefaults.fromMap(data['defaults']);
        await saveDefaults(defaults);
      }
      
      if (data['batches'] != null) {
        final List<dynamic> batchesJson = data['batches'];
        html.window.localStorage[_batchesKey] = jsonEncode(batchesJson);
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }
  
  static Future<void> clearAllData() async {
    try {
      html.window.localStorage.remove(_defaultsKey);
      html.window.localStorage.remove(_batchesKey);
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }
}