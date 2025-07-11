import '../models/configurable_defaults.dart';
import 'web_storage_service.dart';

class DefaultsService {
  static ConfigurableDefaults? _cachedDefaults;

  // Get current configurable defaults (with caching)
  static Future<ConfigurableDefaults> getDefaults() async {
    _cachedDefaults ??= await WebStorageService.getDefaults();
    return _cachedDefaults!;
  }

  // Update configurable defaults
  static Future<void> updateDefaults(ConfigurableDefaults defaults) async {
    await WebStorageService.saveDefaults(defaults);
    _cachedDefaults = defaults; // Update cache
  }

  // Reset to factory defaults
  static Future<void> resetToDefaults() async {
    final factoryDefaults = ConfigurableDefaults(); // Creates with default values
    await WebStorageService.saveDefaults(factoryDefaults);
    _cachedDefaults = null; // Clear cache to force reload
  }

  // Clear cache (useful after database reset)
  static void clearCache() {
    _cachedDefaults = null;
  }

  // Update specific values with validation
  static Future<void> updateWorkerCalculation({
    required double fixedAmount,
    required double denominator,
  }) async {
    if (fixedAmount <= 0 || denominator <= 0) {
      throw Exception('Worker calculation values must be positive');
    }
    
    final current = await getDefaults();
    final updated = current.copyWith(
      workerFixedAmount: fixedAmount,
      fixedDenominator: denominator,
    );
    await updateDefaults(updated);
  }

  static Future<void> updateRentCalculation({
    required double fixedAmount,
    required double denominator,
  }) async {
    if (fixedAmount <= 0 || denominator <= 0) {
      throw Exception('Rent calculation values must be positive');
    }
    
    final current = await getDefaults();
    final updated = current.copyWith(
      rentFixedAmount: fixedAmount,
      fixedDenominator: denominator,
    );
    await updateDefaults(updated);
  }

  static Future<void> updateAccountCalculation({
    required double fixedAmount,
    required double denominator,
  }) async {
    if (fixedAmount <= 0 || denominator <= 0) {
      throw Exception('Account calculation values must be positive');
    }
    
    final current = await getDefaults();
    final updated = current.copyWith(
      accountFixedAmount: fixedAmount,
      fixedDenominator: denominator,
    );
    await updateDefaults(updated);
  }

  static Future<void> updateByproductFormulas({
    double? cuPercentage,
    double? tinNumerator,
    double? tinDenominator,
  }) async {
    if (cuPercentage != null && cuPercentage < 0) {
      throw Exception('CU percentage cannot be negative');
    }
    if (tinNumerator != null && tinNumerator < 0) {
      throw Exception('TIN numerator cannot be negative');
    }
    if (tinDenominator != null && tinDenominator <= 0) {
      throw Exception('TIN denominator must be positive');
    }
    
    final current = await getDefaults();
    final updated = current.copyWith(
      cuPercentage: cuPercentage,
      tinNumerator: tinNumerator,
      tinDenominator: tinDenominator,
    );
    await updateDefaults(updated);
  }

  static Future<void> updateDefaultRates({
    double? pdRate,
    double? cuRate,
    double? tinRate,
    double? otherRate,
    double? nitricRate,
    double? hclRate,
  }) async {
    // Validate all rates are positive
    if (pdRate != null && pdRate <= 0) throw Exception('PD rate must be positive');
    if (cuRate != null && cuRate <= 0) throw Exception('CU rate must be positive');
    if (tinRate != null && tinRate <= 0) throw Exception('TIN rate must be positive');
    if (otherRate != null && otherRate <= 0) throw Exception('Other rate must be positive');
    if (nitricRate != null && nitricRate <= 0) throw Exception('Nitric rate must be positive');
    if (hclRate != null && hclRate <= 0) throw Exception('HCL rate must be positive');
    
    final current = await getDefaults();
    final updated = current.copyWith(
      defaultPdRate: pdRate,
      defaultCuRate: cuRate,
      defaultTinRate: tinRate,
      defaultOtherRate: otherRate,
      defaultNitricRate: nitricRate,
      defaultHclRate: hclRate,
    );
    await updateDefaults(updated);
  }

  // Get specific calculated rates
  static Future<double> getWorkerRate() async {
    final defaults = await getDefaults();
    return defaults.calculatedWorkerRate;
  }

  static Future<double> getRentRate() async {
    final defaults = await getDefaults();
    return defaults.calculatedRentRate;
  }

  static Future<double> getAccountRate() async {
    final defaults = await getDefaults();
    return defaults.calculatedAccountRate;
  }

  // Get default material rates
  static Future<Map<String, double>> getDefaultRates() async {
    final defaults = await getDefaults();
    return {
      'worker': defaults.calculatedWorkerRate,
      'rent': defaults.calculatedRentRate,
      'account': defaults.calculatedAccountRate,
      'nitric': defaults.defaultNitricRate,
      'hcl': defaults.defaultHclRate,
      'other': defaults.defaultOtherRate,
      'pd': defaults.defaultPdRate,
      'cu': defaults.defaultCuRate,
      'tin': defaults.defaultTinRate,
    };
  }

  // Calculate quantities based on current defaults
  static Future<Map<String, double>> calculateQuantities(double pattiQuantity) async {
    final defaults = await getDefaults();
    
    return {
      'patti': pattiQuantity,
      'nitric': pattiQuantity * 1.4,
      'hcl': pattiQuantity * 1.4 * 3.0,
      'worker': pattiQuantity,
      'rent': pattiQuantity,
      'other': pattiQuantity,
      'account': pattiQuantity,
      'cu': defaults.calculateCuQuantity(pattiQuantity),
      'tin': defaults.calculateTinQuantity(pattiQuantity),
    };
  }

  // Get formula display strings
  static Future<Map<String, String>> getFormulaDisplays() async {
    final defaults = await getDefaults();
    return {
      'worker': defaults.workerRateFormula,
      'rent': defaults.rentRateFormula,
      'account': defaults.accountRateFormula,
      'cu_quantity': defaults.cuQuantityFormula,
      'tin_quantity': defaults.tinQuantityFormula,
    };
  }

  // Validate defaults
  static Future<List<String>> validateDefaults() async {
    final defaults = await getDefaults();
    return defaults.validationErrors;
  }

  // Export/Import functionality for backup
  static Future<Map<String, dynamic>> exportDefaults() async {
    final defaults = await getDefaults();
    return defaults.toMap();
  }

  static Future<void> importDefaults(Map<String, dynamic> data) async {
    try {
      final defaults = ConfigurableDefaults.fromMap(data);
      final errors = defaults.validationErrors;
      if (errors.isNotEmpty) {
        throw Exception('Invalid defaults data: ${errors.join(', ')}');
      }
      await updateDefaults(defaults);
    } catch (e) {
      throw Exception('Failed to import defaults: $e');
    }
  }
}