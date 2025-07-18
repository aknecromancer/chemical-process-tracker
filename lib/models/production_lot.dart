import 'package:uuid/uuid.dart';
import '../services/calculation_engine.dart';

/// Production LOT model for multi-day batch tracking
class ProductionLot {
  final String id;
  final String lotNumber;
  final DateTime startDate;
  final DateTime? completedDate;
  final LotStatus status;
  final double pattiQuantity;
  final double pattiRate;
  final double? pdQuantity;
  final Map<String, double> customRates;
  final List<Map<String, dynamic>> manualEntries;
  final CalculationResult? calculationResult;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  ProductionLot({
    String? id,
    required this.lotNumber,
    required this.startDate,
    this.completedDate,
    required this.status,
    required this.pattiQuantity,
    required this.pattiRate,
    this.pdQuantity,
    required this.customRates,
    required this.manualEntries,
    this.calculationResult,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.notes,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lotNumber': lotNumber,
      'startDate': startDate.millisecondsSinceEpoch,
      'completedDate': completedDate?.millisecondsSinceEpoch,
      'status': status.name,
      'pattiQuantity': pattiQuantity,
      'pattiRate': pattiRate,
      'pdQuantity': pdQuantity,
      'customRates': customRates,
      'manualEntries': manualEntries,
      'calculationResult': calculationResult?.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  /// Create from JSON
  factory ProductionLot.fromJson(Map<String, dynamic> json) {
    return ProductionLot(
      id: json['id'],
      lotNumber: json['lotNumber'],
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate']),
      completedDate: json['completedDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['completedDate'])
          : null,
      status: LotStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => LotStatus.draft,
      ),
      pattiQuantity: (json['pattiQuantity'] ?? 0).toDouble(),
      pattiRate: (json['pattiRate'] ?? 0).toDouble(),
      pdQuantity: json['pdQuantity']?.toDouble(),
      customRates: Map<String, double>.from(json['customRates'] ?? {}),
      manualEntries: List<Map<String, dynamic>>.from(json['manualEntries'] ?? []),
      calculationResult: json['calculationResult'] != null 
          ? CalculationResult.fromJson(json['calculationResult'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      notes: json['notes'],
    );
  }

  /// Copy with modifications
  ProductionLot copyWith({
    String? id,
    String? lotNumber,
    DateTime? startDate,
    DateTime? completedDate,
    LotStatus? status,
    double? pattiQuantity,
    double? pattiRate,
    double? pdQuantity,
    Map<String, double>? customRates,
    List<Map<String, dynamic>>? manualEntries,
    CalculationResult? calculationResult,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return ProductionLot(
      id: id ?? this.id,
      lotNumber: lotNumber ?? this.lotNumber,
      startDate: startDate ?? this.startDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      pattiQuantity: pattiQuantity ?? this.pattiQuantity,
      pattiRate: pattiRate ?? this.pattiRate,
      pdQuantity: pdQuantity ?? this.pdQuantity,
      customRates: customRates ?? this.customRates,
      manualEntries: manualEntries ?? this.manualEntries,
      calculationResult: calculationResult ?? this.calculationResult,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notes: notes ?? this.notes,
    );
  }

  // Business logic getters
  double get netPnL => calculationResult?.finalProfitLoss ?? 0.0;
  double get totalIncome => (calculationResult?.pdIncome ?? 0.0) + (calculationResult?.netByproductIncome ?? 0.0);
  double get totalExpenses => calculationResult?.phase1TotalCost ?? 0.0;
  double get totalProductIncome => calculationResult?.pdIncome ?? 0.0;
  double get totalByproductIncome => calculationResult?.netByproductIncome ?? 0.0;
  double get pdEfficiency => calculationResult?.pdEfficiency ?? 0.0;
  bool get isProfitable => netPnL > 0;
  bool get isLoss => netPnL < 0;
  bool get isBreakeven => netPnL == 0;

  // Status and date display methods
  String get statusDisplayName {
    switch (status) {
      case LotStatus.draft:
        return 'Draft';
      case LotStatus.inProgress:
        return 'In Progress';
      case LotStatus.completed:
        return 'Completed';
      case LotStatus.archived:
        return 'Archived';
    }
  }

  /// Get the display date (completion date if completed, start date otherwise)
  DateTime get displayDate => completedDate ?? startDate;
  
  /// Get the reporting date (used for analytics - completion date if available)
  DateTime get reportingDate => completedDate ?? startDate;
  
  String get dateDisplayString {
    final date = displayDate;
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get duration of the lot
  int get durationInDays {
    if (completedDate != null) {
      return completedDate!.difference(startDate).inDays + 1;
    }
    return DateTime.now().difference(startDate).inDays + 1;
  }

  /// Check if lot is currently active
  bool get isActive => status == LotStatus.inProgress;
  
  /// Check if lot is completed
  bool get isCompleted => status == LotStatus.completed;
  
  /// Check if lot is draft
  bool get isDraft => status == LotStatus.draft;

  // Material count methods
  int get materialCount => manualEntries.length;

  // Profit margin calculation
  double get profitMargin {
    if (totalIncome == 0) return 0;
    return (netPnL / totalIncome) * 100;
  }

  /// Generate next lot number
  static String generateNextLotNumber(List<ProductionLot> existingLots) {
    if (existingLots.isEmpty) {
      return 'LOT001';
    }
    
    // Extract numeric part from existing lot numbers
    final numbers = existingLots
        .map((lot) => lot.lotNumber)
        .where((lotNumber) => lotNumber.startsWith('LOT'))
        .map((lotNumber) => int.tryParse(lotNumber.substring(3)) ?? 0)
        .toList();
    
    if (numbers.isEmpty) {
      return 'LOT001';
    }
    
    final maxNumber = numbers.reduce((a, b) => a > b ? a : b);
    return 'LOT${(maxNumber + 1).toString().padLeft(3, '0')}';
  }

  /// Mark lot as completed
  ProductionLot markAsCompleted() {
    return copyWith(
      status: LotStatus.completed,
      completedDate: DateTime.now(),
    );
  }

  /// Mark lot as in progress
  ProductionLot markAsInProgress() {
    return copyWith(
      status: LotStatus.inProgress,
    );
  }

  @override
  String toString() {
    return 'ProductionLot(lotNumber: $lotNumber, status: ${status.name}, startDate: $startDate, completedDate: $completedDate)';
  }
}

/// LOT status enumeration
enum LotStatus {
  draft,      // LOT created but not started
  inProgress, // LOT is currently being processed
  completed,  // LOT is completed
  archived,   // LOT is archived
}

/// Extension for status colors and icons
extension LotStatusExtension on LotStatus {
  String get displayName {
    switch (this) {
      case LotStatus.draft:
        return 'Draft';
      case LotStatus.inProgress:
        return 'In Progress';
      case LotStatus.completed:
        return 'Completed';
      case LotStatus.archived:
        return 'Archived';
    }
  }
  
  /// Get appropriate color for the status
  String get colorHex {
    switch (this) {
      case LotStatus.draft:
        return '#F59E0B'; // Amber
      case LotStatus.inProgress:
        return '#3B82F6'; // Blue
      case LotStatus.completed:
        return '#10B981'; // Green
      case LotStatus.archived:
        return '#6B7280'; // Gray
    }
  }
}