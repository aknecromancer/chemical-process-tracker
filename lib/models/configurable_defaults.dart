import 'package:uuid/uuid.dart';

class ConfigurableDefaults {
  final String id;
  
  // Rate calculation bases (globally editable, persistent)
  final double workerFixedAmount;
  final double rentFixedAmount;
  final double accountFixedAmount;
  final double fixedDenominator;
  
  // Byproduct quantity formulas (globally editable)
  final double cuPercentage; // CU = Patti × cuPercentage
  final double tinNumerator; // TIN = (tinNumerator/tinDenominator) × Patti
  final double tinDenominator;
  
  // Default rates (globally editable)
  final double defaultPdRate;
  final double defaultCuRate;
  final double defaultTinRate;
  final double defaultOtherRate;
  final double defaultNitricRate;
  final double defaultHclRate;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  ConfigurableDefaults({
    String? id,
    this.workerFixedAmount = 38000,
    this.rentFixedAmount = 25000,
    this.accountFixedAmount = 5000,
    this.fixedDenominator = 4500,
    this.cuPercentage = 10.0, // 10% of Patti
    this.tinNumerator = 11,
    this.tinDenominator = 30,
    this.defaultPdRate = 12000,
    this.defaultCuRate = 600,
    this.defaultTinRate = 38,
    this.defaultOtherRate = 4,
    this.defaultNitricRate = 26,
    this.defaultHclRate = 1.7,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ConfigurableDefaults copyWith({
    String? id,
    double? workerFixedAmount,
    double? rentFixedAmount,
    double? accountFixedAmount,
    double? fixedDenominator,
    double? cuPercentage,
    double? tinNumerator,
    double? tinDenominator,
    double? defaultPdRate,
    double? defaultCuRate,
    double? defaultTinRate,
    double? defaultOtherRate,
    double? defaultNitricRate,
    double? defaultHclRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConfigurableDefaults(
      id: id ?? this.id,
      workerFixedAmount: workerFixedAmount ?? this.workerFixedAmount,
      rentFixedAmount: rentFixedAmount ?? this.rentFixedAmount,
      accountFixedAmount: accountFixedAmount ?? this.accountFixedAmount,
      fixedDenominator: fixedDenominator ?? this.fixedDenominator,
      cuPercentage: cuPercentage ?? this.cuPercentage,
      tinNumerator: tinNumerator ?? this.tinNumerator,
      tinDenominator: tinDenominator ?? this.tinDenominator,
      defaultPdRate: defaultPdRate ?? this.defaultPdRate,
      defaultCuRate: defaultCuRate ?? this.defaultCuRate,
      defaultTinRate: defaultTinRate ?? this.defaultTinRate,
      defaultOtherRate: defaultOtherRate ?? this.defaultOtherRate,
      defaultNitricRate: defaultNitricRate ?? this.defaultNitricRate,
      defaultHclRate: defaultHclRate ?? this.defaultHclRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_fixed_amount': workerFixedAmount,
      'rent_fixed_amount': rentFixedAmount,
      'account_fixed_amount': accountFixedAmount,
      'fixed_denominator': fixedDenominator,
      'cu_percentage': cuPercentage,
      'tin_numerator': tinNumerator,
      'tin_denominator': tinDenominator,
      'default_pd_rate': defaultPdRate,
      'default_cu_rate': defaultCuRate,
      'default_tin_rate': defaultTinRate,
      'default_other_rate': defaultOtherRate,
      'default_nitric_rate': defaultNitricRate,
      'default_hcl_rate': defaultHclRate,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ConfigurableDefaults.fromMap(Map<String, dynamic> map) {
    return ConfigurableDefaults(
      id: map['id'],
      workerFixedAmount: map['worker_fixed_amount']?.toDouble() ?? 38000,
      rentFixedAmount: map['rent_fixed_amount']?.toDouble() ?? 25000,
      accountFixedAmount: map['account_fixed_amount']?.toDouble() ?? 5000,
      fixedDenominator: map['fixed_denominator']?.toDouble() ?? 4500,
      cuPercentage: map['cu_percentage']?.toDouble() ?? 0.10,
      tinNumerator: map['tin_numerator']?.toDouble() ?? 11,
      tinDenominator: map['tin_denominator']?.toDouble() ?? 30,
      defaultPdRate: map['default_pd_rate']?.toDouble() ?? 12000,
      defaultCuRate: map['default_cu_rate']?.toDouble() ?? 600,
      defaultTinRate: map['default_tin_rate']?.toDouble() ?? 38,
      defaultOtherRate: map['default_other_rate']?.toDouble() ?? 4,
      defaultNitricRate: map['default_nitric_rate']?.toDouble() ?? 26,
      defaultHclRate: map['default_hcl_rate']?.toDouble() ?? 1.7,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  // Calculated rate getters
  double get calculatedWorkerRate => workerFixedAmount / fixedDenominator;
  double get calculatedRentRate => rentFixedAmount / fixedDenominator;
  double get calculatedAccountRate => accountFixedAmount / fixedDenominator;

  // Quantity calculation methods
  double calculateCuQuantity(double pattiQuantity) => pattiQuantity * (cuPercentage / 100);
  double calculateTinQuantity(double pattiQuantity) => (tinNumerator / tinDenominator) * pattiQuantity;

  // Formula display strings
  String get workerRateFormula => '${workerFixedAmount.toStringAsFixed(0)} ÷ ${fixedDenominator.toStringAsFixed(0)} = ${calculatedWorkerRate.toStringAsFixed(6)}';
  String get rentRateFormula => '${rentFixedAmount.toStringAsFixed(0)} ÷ ${fixedDenominator.toStringAsFixed(0)} = ${calculatedRentRate.toStringAsFixed(6)}';
  String get accountRateFormula => '${accountFixedAmount.toStringAsFixed(0)} ÷ ${fixedDenominator.toStringAsFixed(0)} = ${calculatedAccountRate.toStringAsFixed(6)}';
  String get cuQuantityFormula => 'Patti × ${(cuPercentage * 100).toStringAsFixed(1)}%';
  String get tinQuantityFormula => '(${tinNumerator.toStringAsFixed(0)}/${tinDenominator.toStringAsFixed(0)}) × Patti';

  // Validation methods
  bool get isValid {
    return workerFixedAmount > 0 &&
           rentFixedAmount > 0 &&
           accountFixedAmount > 0 &&
           fixedDenominator > 0 &&
           cuPercentage >= 0 &&
           tinNumerator >= 0 &&
           tinDenominator > 0 &&
           defaultPdRate > 0 &&
           defaultCuRate > 0 &&
           defaultTinRate > 0 &&
           defaultOtherRate > 0 &&
           defaultNitricRate > 0 &&
           defaultHclRate > 0;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (workerFixedAmount <= 0) errors.add('Worker fixed amount must be positive');
    if (rentFixedAmount <= 0) errors.add('Rent fixed amount must be positive');
    if (accountFixedAmount <= 0) errors.add('Account fixed amount must be positive');
    if (fixedDenominator <= 0) errors.add('Fixed denominator must be positive');
    if (cuPercentage < 0) errors.add('CU percentage cannot be negative');
    if (tinNumerator < 0) errors.add('TIN numerator cannot be negative');
    if (tinDenominator <= 0) errors.add('TIN denominator must be positive');
    if (defaultPdRate <= 0) errors.add('Default PD rate must be positive');
    if (defaultCuRate <= 0) errors.add('Default CU rate must be positive');
    if (defaultTinRate <= 0) errors.add('Default TIN rate must be positive');
    if (defaultOtherRate <= 0) errors.add('Default Other rate must be positive');
    if (defaultNitricRate <= 0) errors.add('Default Nitric rate must be positive');
    if (defaultHclRate <= 0) errors.add('Default HCL rate must be positive');
    
    return errors;
  }

  @override
  String toString() {
    return 'ConfigurableDefaults(id: $id, workerRate: ${calculatedWorkerRate.toStringAsFixed(2)}, rentRate: ${calculatedRentRate.toStringAsFixed(2)}, accountRate: ${calculatedAccountRate.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConfigurableDefaults && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Factory method for creating default instance
  factory ConfigurableDefaults.createDefault() {
    return ConfigurableDefaults();
  }

  // Method to reset to factory defaults
  ConfigurableDefaults resetToDefaults() {
    return ConfigurableDefaults.createDefault().copyWith(
      id: id,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}