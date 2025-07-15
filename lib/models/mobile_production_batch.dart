import '../services/calculation_engine.dart';

/// Mobile-compatible production batch model with JSON serialization
class MobileProductionBatch {
  final DateTime date;
  final double pattiQuantity;
  final double pattiRate;
  final double? pdQuantity;
  final Map<String, double> customRates;
  final List<Map<String, dynamic>> manualEntries;
  final CalculationResult? calculationResult;
  final DateTime createdAt;

  MobileProductionBatch({
    required this.date,
    required this.pattiQuantity,
    required this.pattiRate,
    this.pdQuantity,
    required this.customRates,
    required this.manualEntries,
    this.calculationResult,
    required this.createdAt,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
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

  /// Create from JSON
  factory MobileProductionBatch.fromJson(Map<String, dynamic> json) {
    return MobileProductionBatch(
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

  /// Copy with modifications
  MobileProductionBatch copyWith({
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

  @override
  String toString() {
    return 'MobileProductionBatch(date: $date, pattiQuantity: $pattiQuantity, pattiRate: $pattiRate)';
  }
}