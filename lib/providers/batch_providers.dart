import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/configurable_defaults.dart';
import '../models/production_batch.dart';
import '../models/material_template.dart';
import '../services/calculation_engine.dart';
import '../services/defaults_service.dart';
import '../services/batch_processing_service.dart';

// Provider for configurable defaults
final configurableDefaultsProvider = FutureProvider<ConfigurableDefaults>((ref) async {
  return await DefaultsService.getDefaults();
});

// Provider for calculation engine
final calculationEngineProvider = Provider<AdvancedCalculationEngine?>((ref) {
  final defaultsAsync = ref.watch(configurableDefaultsProvider);
  return defaultsAsync.when(
    data: (defaults) => AdvancedCalculationEngine(defaults),
    loading: () => null,
    error: (error, stack) => null,
  );
});

// Batch entry state
class BatchEntryState {
  final double pattiQuantity;
  final double pattiRate;
  final double? pdQuantity;
  final Map<String, double> customRates;
  final CalculationResult? result;
  final List<String> validationErrors;
  final bool isLoading;

  const BatchEntryState({
    this.pattiQuantity = 0,
    this.pattiRate = 0,
    this.pdQuantity,
    this.customRates = const {},
    this.result,
    this.validationErrors = const [],
    this.isLoading = false,
  });

  BatchEntryState copyWith({
    double? pattiQuantity,
    double? pattiRate,
    double? pdQuantity,
    Map<String, double>? customRates,
    CalculationResult? result,
    List<String>? validationErrors,
    bool? isLoading,
  }) {
    return BatchEntryState(
      pattiQuantity: pattiQuantity ?? this.pattiQuantity,
      pattiRate: pattiRate ?? this.pattiRate,
      pdQuantity: pdQuantity ?? this.pdQuantity,
      customRates: customRates ?? this.customRates,
      result: result ?? this.result,
      validationErrors: validationErrors ?? this.validationErrors,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Batch entry state notifier
class BatchEntryNotifier extends StateNotifier<BatchEntryState> {
  final AdvancedCalculationEngine _engine;

  BatchEntryNotifier(this._engine) : super(const BatchEntryState());

  void updatePattiQuantity(double quantity) {
    state = state.copyWith(pattiQuantity: quantity);
    _recalculate();
  }

  void updatePattiRate(double rate) {
    state = state.copyWith(pattiRate: rate);
    _recalculate();
  }

  void updatePdQuantity(double? quantity) {
    state = state.copyWith(pdQuantity: quantity);
    _recalculate();
  }

  void updateCustomRate(String materialId, double rate) {
    final newRates = Map<String, double>.from(state.customRates);
    newRates[materialId] = rate;
    state = state.copyWith(customRates: newRates);
    _recalculate();
  }

  void removeCustomRate(String materialId) {
    final newRates = Map<String, double>.from(state.customRates);
    newRates.remove(materialId);
    state = state.copyWith(customRates: newRates);
    _recalculate();
  }

  void _recalculate() {
    // Validate inputs
    final errors = _engine.validateInputs(
      pattiQuantity: state.pattiQuantity,
      pattiRate: state.pattiRate,
      pdQuantity: state.pdQuantity,
      customRates: state.customRates,
    );

    // Calculate results
    final result = _engine.calculateProcess(
      pattiQuantity: state.pattiQuantity,
      pattiRate: state.pattiRate,
      pdQuantity: state.pdQuantity,
      customRates: state.customRates,
    );

    state = state.copyWith(
      result: result,
      validationErrors: errors,
    );
  }

  void reset() {
    state = const BatchEntryState();
  }

  void loadFromBatch(ProductionBatch batch) {
    // TODO: Load existing batch data
    state = state.copyWith(isLoading: false);
  }

  Future<void> saveBatch(String batchId) async {
    state = state.copyWith(isLoading: true);
    try {
      // TODO: Save batch using BatchProcessingService
      // This will be implemented when we have the full batch entry workflow
    } catch (e) {
      // Handle error
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Helper methods
  List<MaterialInput> get materials {
    if (state.result == null) return [];
    return _engine.createMaterialInputs(
      pattiQuantity: state.pattiQuantity,
      pattiRate: state.pattiRate,
      pdQuantity: state.pdQuantity,
      customRates: state.customRates,
    );
  }

  List<MaterialInput> get rawMaterials {
    return materials.where((m) => m.category == MaterialCategory.raw).toList();
  }

  List<MaterialInput> get derivedMaterials {
    return materials.where((m) => m.category == MaterialCategory.derived).toList();
  }

  List<MaterialInput> get products {
    return materials.where((m) => m.category == MaterialCategory.product).toList();
  }

  List<MaterialInput> get byproducts {
    return materials.where((m) => m.category == MaterialCategory.byproduct).toList();
  }

  bool get hasValidInputs {
    return state.pattiQuantity > 0 && 
           state.pattiRate > 0 && 
           state.validationErrors.isEmpty;
  }

  bool get isProfitNegative {
    return state.result?.isProfitNegative ?? false;
  }

  double get pdEfficiency {
    return state.result?.pdEfficiency ?? 0;
  }

  bool get isPdEfficiencyValid {
    final efficiency = pdEfficiency;
    return efficiency >= 0.1 && efficiency <= 10.0;
  }
}

// Provider for batch entry state
final batchEntryProvider = StateNotifierProvider.family<BatchEntryNotifier, BatchEntryState, DateTime>((ref, date) {
  final engine = ref.watch(calculationEngineProvider);
  if (engine == null) {
    throw Exception('Calculation engine not available');
  }
  return BatchEntryNotifier(engine);
});

// Provider for current batch
final currentBatchProvider = FutureProvider.family<ProductionBatch?, DateTime>((ref, date) async {
  return await BatchProcessingService.getBatchByDate(date);
});

// Provider for copying previous batch data
final previousBatchProvider = FutureProvider.family<ProductionBatch?, DateTime>((ref, date) async {
  final previousDate = date.subtract(const Duration(days: 1));
  return await BatchProcessingService.getBatchByDate(previousDate);
});

// Provider for default rates
final defaultRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  return await DefaultsService.getDefaultRates();
});

// Provider for formula displays
final formulaDisplaysProvider = FutureProvider<Map<String, String>>((ref) async {
  return await DefaultsService.getFormulaDisplays();
});