import 'package:uuid/uuid.dart';
import 'batch_material.dart';
import '../services/calculation_engine.dart';

/// Mobile-compatible production batch model with JSON serialization
class MobileProductionBatch {
  final String id;
  final DateTime date;
  final double pattiQuantity;
  final double pattiRate;
  final double? pdQuantity;
  final Map<String, double> customRates;
  final List<Map<String, dynamic>> manualEntries;
  final CalculationResult? calculationResult;
  final DateTime createdAt;

  MobileProductionBatch({
    String? id,
    required this.date,
    required this.pattiQuantity,
    required this.pattiRate,
    this.pdQuantity,
    required this.customRates,
    required this.manualEntries,
    this.calculationResult,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'pattiQuantity': pattiQuantity,
      'pattiRate': pattiRate,
      'pdQuantity': pdQuantity,
      'customRates': customRates,
      'manualEntries': manualEntries,
      'calculationResult': calculationResult?.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Convert to Map for compatibility with web storage
  Map<String, dynamic> toMap() {
    return toJson();
  }

  /// Create from JSON
  factory MobileProductionBatch.fromJson(Map<String, dynamic> json) {
    return MobileProductionBatch(
      id: json['id'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      pattiQuantity: (json['pattiQuantity'] ?? 0).toDouble(),
      pattiRate: (json['pattiRate'] ?? 0).toDouble(),
      pdQuantity: json['pdQuantity']?.toDouble(),
      customRates: Map<String, double>.from(json['customRates'] ?? {}),
      manualEntries: List<Map<String, dynamic>>.from(json['manualEntries'] ?? []),
      calculationResult: json['calculationResult'] != null 
          ? CalculationResult.fromJson(json['calculationResult'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  /// Create from Map for compatibility with web storage
  factory MobileProductionBatch.fromMap(Map<String, dynamic> map) {
    return MobileProductionBatch.fromJson(map);
  }

  /// Copy with modifications
  MobileProductionBatch copyWith({
    String? id,
    DateTime? date,
    double? pattiQuantity,
    double? pattiRate,
    double? pdQuantity,
    Map<String, double>? customRates,
    List<Map<String, dynamic>>? manualEntries,
    CalculationResult? calculationResult,
    DateTime? createdAt,
  }) {
    return MobileProductionBatch(
      id: id ?? this.id,
      date: date ?? this.date,
      pattiQuantity: pattiQuantity ?? this.pattiQuantity,
      pattiRate: pattiRate ?? this.pattiRate,
      pdQuantity: pdQuantity ?? this.pdQuantity,
      customRates: customRates ?? this.customRates,
      manualEntries: manualEntries ?? this.manualEntries,
      calculationResult: calculationResult ?? this.calculationResult,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Getter methods for compatibility with analytics and screens
  double get netPnL => calculationResult?.finalProfitLoss ?? 0.0;
  double get totalIncome => (calculationResult?.pdIncome ?? 0.0) + (calculationResult?.netByproductIncome ?? 0.0);
  double get totalExpenses => calculationResult?.phase1TotalCost ?? 0.0;
  double get totalRawMaterials => 0.0; // Not applicable for mobile
  double get totalDerivedMaterials => 0.0; // Not applicable for mobile
  double get totalProductIncome => calculationResult?.pdIncome ?? 0.0;
  double get totalByproductIncome => calculationResult?.netByproductIncome ?? 0.0;
  double get pdEfficiency => calculationResult?.pdEfficiency ?? 0.0;
  bool get isProfitable => netPnL > 0;
  bool get isLoss => netPnL < 0;
  bool get isBreakeven => netPnL == 0;
  
  // Status and date display methods
  BatchStatus get status => BatchStatus.draft; // Default for mobile
  String get statusDisplayName => 'Draft';
  String get dateDisplayString => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  DateTime get updatedAt => createdAt;
  
  // Material count methods (simplified for mobile)
  int get materialCount => manualEntries.length;
  List<dynamic> get rawMaterials => [];
  List<dynamic> get derivedMaterials => [];
  List<dynamic> get products => [];
  List<dynamic> get byproducts => [];
  
  // Profit margin calculation
  double get profitMargin {
    if (totalIncome == 0) return 0;
    return (netPnL / totalIncome) * 100;
  }

  @override
  String toString() {
    return 'MobileProductionBatch(date: $date, pattiQuantity: $pattiQuantity, pattiRate: $pattiRate)';
  }
}

// Compatibility alias - use MobileProductionBatch for new mobile features
typedef ProductionBatch = MobileProductionBatch;

enum BatchStatus {
  draft,
  completed,
  archived,
}

