import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/production_lot.dart';
import '../models/configurable_defaults.dart';

/// LOT-based storage service for managing production lots
class LotStorageService {
  static const String _defaultsKey = 'chemical_tracker_defaults';
  static const String _lotsKey = 'chemical_tracker_lots';
  static const String _nextLotNumberKey = 'chemical_tracker_next_lot_number';

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

  /// Get all lots from SharedPreferences
  static Future<List<ProductionLot>> getAllLots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_lotsKey);
      if (data == null) return [];

      final jsonList = jsonDecode(data) as List<dynamic>;
      return jsonList
          .map((json) => ProductionLot.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading lots: $e');
      return [];
    }
  }

  /// Save lot to SharedPreferences
  static Future<void> saveLot(ProductionLot lot) async {
    try {
      final lots = await getAllLots();
      
      // Check if lot already exists
      final existingIndex = lots.indexWhere((l) => l.id == lot.id);
      
      if (existingIndex != -1) {
        lots[existingIndex] = lot;
      } else {
        lots.add(lot);
      }
      
      // Sort by start date (newest first)
      lots.sort((a, b) => b.startDate.compareTo(a.startDate));
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = lots.map((lot) => lot.toJson()).toList();
      await prefs.setString(_lotsKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving lot: $e');
      rethrow;
    }
  }

  /// Get lot by ID from SharedPreferences
  static Future<ProductionLot?> getLotById(String id) async {
    try {
      final lots = await getAllLots();
      return lots.where((lot) => lot.id == id).firstOrNull;
    } catch (e) {
      print('Error getting lot by ID: $e');
      return null;
    }
  }

  /// Get lot by lot number from SharedPreferences
  static Future<ProductionLot?> getLotByNumber(String lotNumber) async {
    try {
      final lots = await getAllLots();
      return lots.where((lot) => lot.lotNumber == lotNumber).firstOrNull;
    } catch (e) {
      print('Error getting lot by number: $e');
      return null;
    }
  }

  /// Get active (draft or in-progress) lots
  static Future<List<ProductionLot>> getActiveLots() async {
    try {
      final lots = await getAllLots();
      return lots.where((lot) => 
        lot.status == LotStatus.draft || 
        lot.status == LotStatus.inProgress
      ).toList();
    } catch (e) {
      print('Error getting active lots: $e');
      return [];
    }
  }

  /// Get completed lots for analytics (ordered by completion date)
  static Future<List<ProductionLot>> getCompletedLots() async {
    try {
      final lots = await getAllLots();
      final completedLots = lots.where((lot) => 
        lot.status == LotStatus.completed && lot.completedDate != null
      ).toList();
      
      // Sort by completion date (newest first)
      completedLots.sort((a, b) => b.completedDate!.compareTo(a.completedDate!));
      
      return completedLots;
    } catch (e) {
      print('Error getting completed lots: $e');
      return [];
    }
  }

  /// Get lots completed in a date range
  static Future<List<ProductionLot>> getLotsCompletedInRange(
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final completedLots = await getCompletedLots();
      return completedLots.where((lot) {
        final completedDate = lot.completedDate!;
        return completedDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               completedDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      print('Error getting lots in range: $e');
      return [];
    }
  }

  /// Get lots completed in the last N days
  static Future<List<ProductionLot>> getRecentCompletedLots(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getLotsCompletedInRange(startDate, endDate);
  }

  /// Delete lot from SharedPreferences
  static Future<void> deleteLot(String id) async {
    try {
      final lots = await getAllLots();
      lots.removeWhere((lot) => lot.id == id);
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = lots.map((lot) => lot.toJson()).toList();
      await prefs.setString(_lotsKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error deleting lot: $e');
      rethrow;
    }
  }

  /// Update existing lot in SharedPreferences
  static Future<void> updateLot(ProductionLot lot) async {
    // For SharedPreferences, update is the same as save
    await saveLot(lot);
  }

  /// Generate next lot number
  static Future<String> generateNextLotNumber() async {
    try {
      final lots = await getAllLots();
      return ProductionLot.generateNextLotNumber(lots);
    } catch (e) {
      print('Error generating lot number: $e');
      return 'LOT001';
    }
  }

  /// Create new lot
  static Future<ProductionLot> createNewLot({
    String? lotNumber,
    DateTime? startDate,
    double? pattiQuantity,
    double? pattiRate,
    Map<String, double>? customRates,
    List<Map<String, dynamic>>? manualEntries,
  }) async {
    final nextLotNumber = lotNumber ?? await generateNextLotNumber();
    
    final lot = ProductionLot(
      lotNumber: nextLotNumber,
      startDate: startDate ?? DateTime.now(),
      status: LotStatus.draft,
      pattiQuantity: pattiQuantity ?? 0.0,
      pattiRate: pattiRate ?? 0.0,
      customRates: customRates ?? {},
      manualEntries: manualEntries ?? [],
    );
    
    await saveLot(lot);
    return lot;
  }

  /// Mark lot as in progress
  static Future<ProductionLot> markLotAsInProgress(String lotId) async {
    final lot = await getLotById(lotId);
    if (lot == null) throw Exception('Lot not found');
    
    final updatedLot = lot.markAsInProgress();
    await saveLot(updatedLot);
    return updatedLot;
  }

  /// Complete lot
  static Future<ProductionLot> completeLot(String lotId) async {
    final lot = await getLotById(lotId);
    if (lot == null) throw Exception('Lot not found');
    
    final completedLot = lot.markAsCompleted();
    await saveLot(completedLot);
    return completedLot;
  }

  /// Get analytics data based on completion dates
  static Future<Map<String, dynamic>> getAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
    int? lastDays,
  }) async {
    try {
      List<ProductionLot> lots;
      
      if (lastDays != null) {
        lots = await getRecentCompletedLots(lastDays);
      } else if (startDate != null && endDate != null) {
        lots = await getLotsCompletedInRange(startDate, endDate);
      } else {
        lots = await getCompletedLots();
      }

      final totalLots = lots.length;
      final totalRevenue = lots.fold(0.0, (sum, lot) => 
        sum + (lot.pattiQuantity * lot.pattiRate));
      final totalCost = lots.fold(0.0, (sum, lot) => 
        sum + (lot.calculationResult?.totalCost ?? 0));
      final totalProfit = totalRevenue - totalCost;
      final profitableLots = lots.where((lot) => lot.isProfitable).length;
      final lossLots = lots.where((lot) => lot.isLoss).length;
      
      final avgProfit = totalLots > 0 ? totalProfit / totalLots : 0.0;
      final avgEfficiency = lots.where((lot) => lot.calculationResult != null).isEmpty
          ? 0.0
          : lots.where((lot) => lot.calculationResult != null)
              .fold(0.0, (sum, lot) => sum + lot.pdEfficiency) / 
              lots.where((lot) => lot.calculationResult != null).length;
      
      final profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;
      
      return {
        'totalLots': totalLots,
        'totalRevenue': totalRevenue,
        'totalCost': totalCost,
        'totalProfit': totalProfit,
        'profitableLots': profitableLots,
        'lossLots': lossLots,
        'avgProfit': avgProfit,
        'avgEfficiency': avgEfficiency,
        'profitMargin': profitMargin,
        'successRate': totalLots > 0 ? (profitableLots / totalLots) * 100 : 0.0,
      };
    } catch (e) {
      print('Error getting analytics data: $e');
      return {};
    }
  }

  /// Search lots by criteria
  static Future<List<ProductionLot>> searchLots({
    String? lotNumber,
    LotStatus? status,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    DateTime? completedDateFrom,
    DateTime? completedDateTo,
    double? minProfit,
    double? maxProfit,
  }) async {
    try {
      final lots = await getAllLots();
      
      return lots.where((lot) {
        // Filter by lot number
        if (lotNumber != null && !lot.lotNumber.toLowerCase().contains(lotNumber.toLowerCase())) {
          return false;
        }
        
        // Filter by status
        if (status != null && lot.status != status) {
          return false;
        }
        
        // Filter by start date range
        if (startDateFrom != null && lot.startDate.isBefore(startDateFrom)) {
          return false;
        }
        if (startDateTo != null && lot.startDate.isAfter(startDateTo)) {
          return false;
        }
        
        // Filter by completed date range
        if (completedDateFrom != null) {
          if (lot.completedDate == null || lot.completedDate!.isBefore(completedDateFrom)) {
            return false;
          }
        }
        if (completedDateTo != null) {
          if (lot.completedDate == null || lot.completedDate!.isAfter(completedDateTo)) {
            return false;
          }
        }
        
        // Filter by profit range
        if (minProfit != null && lot.netPnL < minProfit) {
          return false;
        }
        if (maxProfit != null && lot.netPnL > maxProfit) {
          return false;
        }
        
        return true;
      }).toList();
    } catch (e) {
      print('Error searching lots: $e');
      return [];
    }
  }

  /// Clear all data from SharedPreferences
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_defaultsKey);
      await prefs.remove(_lotsKey);
      await prefs.remove(_nextLotNumberKey);
    } catch (e) {
      print('Error clearing data: $e');
      rethrow;
    }
  }

  /// Migrate existing batch data to LOT format
  static Future<void> migrateBatchesToLots() async {
    try {
      // This would be called once to migrate existing date-based batches to LOT-based system
      // For now, we'll implement a basic migration strategy
      print('Migration from batches to lots would be implemented here');
    } catch (e) {
      print('Error migrating batches to lots: $e');
      rethrow;
    }
  }
}