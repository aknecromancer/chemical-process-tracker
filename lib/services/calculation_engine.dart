import '../models/configurable_defaults.dart';
import '../models/batch_material.dart';
import '../models/material_template.dart';

class CalculationResult {
  final double phase1TotalCost;
  final double pdIncome;
  final double cuIncome;
  final double tinIncome;
  final double tinCost;
  final double netByproductIncome;
  final double grossProfit;
  final double netProfit;
  final double pdEfficiency;
  final double materialCostPerUnit;
  final double chemicalCostPerUnit;
  final double otherCostPerUnit;
  final double profitPer100kg;
  final double costPer1kgPd;
  final bool isProfitNegative;
  final Map<String, double> materialCosts;
  final Map<String, double> unitCosts;

  CalculationResult({
    required this.phase1TotalCost,
    required this.pdIncome,
    required this.cuIncome,
    required this.tinIncome,
    required this.tinCost,
    required this.netByproductIncome,
    required this.grossProfit,
    required this.netProfit,
    required this.pdEfficiency,
    required this.materialCostPerUnit,
    required this.chemicalCostPerUnit,
    required this.otherCostPerUnit,
    required this.profitPer100kg,
    required this.costPer1kgPd,
    required this.isProfitNegative,
    required this.materialCosts,
    required this.unitCosts,
  });
}

class MaterialInput {
  final String materialId;
  final String name;
  final double rate;
  final double quantity;
  final double amount;
  final bool isCalculated;
  final bool isDefaultRate;
  final MaterialCategory category;

  MaterialInput({
    required this.materialId,
    required this.name,
    required this.rate,
    required this.quantity,
    required this.category,
    double? amount,
    this.isCalculated = false,
    this.isDefaultRate = false,
  }) : amount = amount ?? (rate * quantity);

  MaterialInput copyWith({
    String? materialId,
    String? name,
    double? rate,
    double? quantity,
    double? amount,
    bool? isCalculated,
    bool? isDefaultRate,
    MaterialCategory? category,
  }) {
    return MaterialInput(
      materialId: materialId ?? this.materialId,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      isCalculated: isCalculated ?? this.isCalculated,
      isDefaultRate: isDefaultRate ?? this.isDefaultRate,
      category: category ?? this.category,
    );
  }

  String get displayString => '${name}: ${quantity.toStringAsFixed(2)} × ₹${rate.toStringAsFixed(2)} = ₹${amount.toStringAsFixed(2)}';
}

class AdvancedCalculationEngine {
  final ConfigurableDefaults defaults;

  AdvancedCalculationEngine(this.defaults);

  // Calculate all derived quantities based on Patti quantity
  Map<String, double> calculateDerivedQuantities(double pattiQuantity) {
    if (pattiQuantity <= 0) {
      return {
        'patti': 0,
        'nitric': 0,
        'hcl': 0,
        'worker': 0,
        'rent': 0,
        'other': 0,
        'account': 0,
        'cu': 0,
        'tin': 0,
      };
    }

    final nitricQuantity = pattiQuantity * 1.4; // Fixed ratio
    final hclQuantity = nitricQuantity * 3.0; // Fixed ratio
    final cuQuantity = defaults.calculateCuQuantity(pattiQuantity);
    final tinQuantity = defaults.calculateTinQuantity(pattiQuantity);

    return {
      'patti': pattiQuantity,
      'nitric': nitricQuantity,
      'hcl': hclQuantity,
      'worker': pattiQuantity, // Same quantity as Patti
      'rent': pattiQuantity, // Same quantity as Patti
      'other': pattiQuantity, // Same quantity as Patti
      'account': pattiQuantity, // Same quantity as Patti
      'cu': cuQuantity,
      'tin': tinQuantity,
    };
  }

  // Calculate all material rates (calculated and default)
  Map<String, double> calculateMaterialRates() {
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

  // Create complete material input list
  List<MaterialInput> createMaterialInputs({
    required double pattiQuantity,
    required double pattiRate,
    double? pdQuantity,
    Map<String, double>? customRates,
  }) {
    final quantities = calculateDerivedQuantities(pattiQuantity);
    final defaultRates = calculateMaterialRates();
    final effectiveRates = {...defaultRates, ...?customRates};

    final materials = <MaterialInput>[
      // Phase 1: Raw and Processing Materials
      MaterialInput(
        materialId: 'patti',
        name: 'Patti',
        rate: pattiRate,
        quantity: quantities['patti']!,
        category: MaterialCategory.raw,
        isCalculated: false,
        isDefaultRate: false,
      ),
      MaterialInput(
        materialId: 'nitric',
        name: 'Nitric',
        rate: effectiveRates['nitric']!,
        quantity: quantities['nitric']!,
        category: MaterialCategory.derived,
        isCalculated: true,
        isDefaultRate: customRates?.containsKey('nitric') != true,
      ),
      MaterialInput(
        materialId: 'hcl',
        name: 'HCL',
        rate: effectiveRates['hcl']!,
        quantity: quantities['hcl']!,
        category: MaterialCategory.derived,
        isCalculated: true,
        isDefaultRate: customRates?.containsKey('hcl') != true,
      ),
      MaterialInput(
        materialId: 'worker',
        name: 'Worker',
        rate: effectiveRates['worker']!,
        quantity: quantities['worker']!,
        category: MaterialCategory.raw,
        isCalculated: true,
        isDefaultRate: true,
      ),
      MaterialInput(
        materialId: 'rent',
        name: 'Rent',
        rate: effectiveRates['rent']!,
        quantity: quantities['rent']!,
        category: MaterialCategory.raw,
        isCalculated: true,
        isDefaultRate: true,
      ),
      MaterialInput(
        materialId: 'other',
        name: 'Other',
        rate: effectiveRates['other']!,
        quantity: quantities['other']!,
        category: MaterialCategory.raw,
        isCalculated: false,
        isDefaultRate: customRates?.containsKey('other') != true,
      ),
      MaterialInput(
        materialId: 'account',
        name: 'Account',
        rate: effectiveRates['account']!,
        quantity: quantities['account']!,
        category: MaterialCategory.raw,
        isCalculated: true,
        isDefaultRate: true,
      ),
    ];

    // Phase 2: Product
    if (pdQuantity != null && pdQuantity > 0) {
      materials.add(MaterialInput(
        materialId: 'pd',
        name: 'PD',
        rate: effectiveRates['pd']!,
        quantity: pdQuantity,
        category: MaterialCategory.product,
        isCalculated: false,
        isDefaultRate: customRates?.containsKey('pd') != true,
      ));
    }

    // Phase 3: Byproducts
    materials.addAll([
      MaterialInput(
        materialId: 'cu',
        name: 'CU',
        rate: effectiveRates['cu']!,
        quantity: quantities['cu']!,
        category: MaterialCategory.byproduct,
        isCalculated: true,
        isDefaultRate: customRates?.containsKey('cu') != true,
      ),
      MaterialInput(
        materialId: 'tin',
        name: 'TIN',
        rate: effectiveRates['tin']!,
        quantity: quantities['tin']!,
        category: MaterialCategory.byproduct,
        isCalculated: true,
        isDefaultRate: customRates?.containsKey('tin') != true,
      ),
    ]);

    return materials;
  }

  // Calculate complete process results
  CalculationResult calculateProcess({
    required double pattiQuantity,
    required double pattiRate,
    double? pdQuantity,
    Map<String, double>? customRates,
    double manualIncome = 0,
    double manualExpenses = 0,
  }) {
    if (pattiQuantity <= 0) {
      return _createZeroResult();
    }

    final materials = createMaterialInputs(
      pattiQuantity: pattiQuantity,
      pattiRate: pattiRate,
      pdQuantity: pdQuantity,
      customRates: customRates,
    );

    // Group materials by category
    final rawMaterials = materials.where((m) => m.category == MaterialCategory.raw).toList();
    final derivedMaterials = materials.where((m) => m.category == MaterialCategory.derived).toList();
    final products = materials.where((m) => m.category == MaterialCategory.product).toList();
    final byproducts = materials.where((m) => m.category == MaterialCategory.byproduct).toList();

    // Calculate Phase 1: Total Cost
    final phase1Materials = [...rawMaterials, ...derivedMaterials];
    final phase1TotalCost = phase1Materials.fold(0.0, (sum, m) => sum + m.amount);

    // Calculate Phase 2: Product Income
    final pdIncome = products.fold(0.0, (sum, m) => sum + m.amount);

    // Calculate Phase 3: Byproduct Income
    final cuMaterial = byproducts.firstWhere((m) => m.materialId == 'cu');
    final tinMaterial = byproducts.firstWhere((m) => m.materialId == 'tin');
    final cuIncome = cuMaterial.amount;
    final tinIncome = tinMaterial.amount;
    final netByproductIncome = cuIncome - tinIncome;

    // Calculate P&L with manual entries
    final grossProfit = pdIncome - phase1TotalCost;
    final netProfit = grossProfit + netByproductIncome + manualIncome - manualExpenses;

    // Calculate efficiency and unit costs
    final pdEfficiency = (pdQuantity != null && pdQuantity > 0 && pattiQuantity > 0) 
        ? (pdQuantity / pattiQuantity) * 100 
        : 0.0;

    // Calculate unit costs
    final materialCostPerUnit = pattiQuantity > 0 ? phase1TotalCost / pattiQuantity : 0.0;
    final chemicalCosts = derivedMaterials.fold(0.0, (sum, m) => sum + m.amount);
    final otherCosts = rawMaterials.fold(0.0, (sum, m) => sum + m.amount);
    final chemicalCostPerUnit = pattiQuantity > 0 ? chemicalCosts / pattiQuantity : 0.0;
    final otherCostPerUnit = pattiQuantity > 0 ? otherCosts / pattiQuantity : 0.0;

    // Calculate profit metrics
    final profitPer100kg = pattiQuantity > 0 ? (netProfit / pattiQuantity) * 100 : 0.0;
    final costPer1kgPd = (pdQuantity != null && pdQuantity > 0) ? phase1TotalCost / pdQuantity : 0.0;

    // Create material costs map
    final materialCosts = <String, double>{};
    final unitCosts = <String, double>{};
    
    for (final material in materials) {
      materialCosts[material.materialId] = material.amount;
      unitCosts[material.materialId] = material.rate;
    }

    return CalculationResult(
      phase1TotalCost: phase1TotalCost,
      pdIncome: pdIncome,
      cuIncome: cuIncome,
      tinIncome: tinIncome,
      tinCost: tinIncome,
      netByproductIncome: netByproductIncome,
      grossProfit: grossProfit,
      netProfit: netProfit,
      pdEfficiency: pdEfficiency,
      materialCostPerUnit: materialCostPerUnit,
      chemicalCostPerUnit: chemicalCostPerUnit,
      otherCostPerUnit: otherCostPerUnit,
      profitPer100kg: profitPer100kg,
      costPer1kgPd: costPer1kgPd,
      isProfitNegative: netProfit < 0,
      materialCosts: materialCosts,
      unitCosts: unitCosts,
    );
  }

  // Validation methods
  bool validatePdEfficiency(double efficiency) {
    return efficiency >= 0.1 && efficiency <= 10.0; // 0.1% to 10%
  }

  List<String> validateInputs({
    required double pattiQuantity,
    required double pattiRate,
    double? pdQuantity,
    Map<String, double>? customRates,
  }) {
    final errors = <String>[];

    if (pattiQuantity <= 0) {
      errors.add('Patti quantity must be greater than 0');
    }
    
    if (pattiRate <= 0) {
      errors.add('Patti rate must be greater than 0');
    }

    if (pdQuantity != null) {
      if (pdQuantity <= 0) {
        errors.add('PD quantity must be greater than 0');
      } else if (pattiQuantity > 0) {
        final efficiency = (pdQuantity / pattiQuantity) * 100;
        if (!validatePdEfficiency(efficiency)) {
          errors.add('PD efficiency ${efficiency.toStringAsFixed(2)}% is outside acceptable range (0.1% - 10%)');
        }
      }
    }

    customRates?.forEach((key, value) {
      if (value <= 0) {
        errors.add('$key rate must be greater than 0');
      }
    });

    return errors;
  }

  // Helper method for zero/invalid results
  CalculationResult _createZeroResult() {
    return CalculationResult(
      phase1TotalCost: 0,
      pdIncome: 0,
      cuIncome: 0,
      tinIncome: 0,
      tinCost: 0,
      netByproductIncome: 0,
      grossProfit: 0,
      netProfit: 0,
      pdEfficiency: 0,
      materialCostPerUnit: 0,
      chemicalCostPerUnit: 0,
      otherCostPerUnit: 0,
      profitPer100kg: 0,
      costPer1kgPd: 0,
      isProfitNegative: false,
      materialCosts: {},
      unitCosts: {},
    );
  }

  // Get material display information
  Map<String, String> getMaterialDisplayInfo() {
    return {
      'worker': defaults.workerRateFormula,
      'rent': defaults.rentRateFormula,
      'account': defaults.accountRateFormula,
      'cu_quantity': defaults.cuQuantityFormula,
      'tin_quantity': defaults.tinQuantityFormula,
    };
  }

  // Calculate suggested PD quantity based on target efficiency
  double calculateSuggestedPdQuantity(double pattiQuantity, double targetEfficiency) {
    if (pattiQuantity <= 0 || targetEfficiency <= 0) return 0;
    return (targetEfficiency / 100) * pattiQuantity;
  }

  // Calculate efficiency from PD quantity
  double calculateEfficiency(double pdQuantity, double pattiQuantity) {
    if (pattiQuantity <= 0) return 0;
    return (pdQuantity / pattiQuantity) * 100;
  }
}