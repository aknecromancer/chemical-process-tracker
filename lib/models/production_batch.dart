import 'package:uuid/uuid.dart';
import 'batch_material.dart';

enum BatchStatus {
  draft,
  completed,
  archived,
}

class ProductionBatch {
  final String id;
  final DateTime date;
  final BatchStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Calculated totals
  final double totalRawMaterials;
  final double totalDerivedMaterials;
  final double totalExpenses;
  final double totalProductIncome;
  final double totalByproductIncome;
  final double totalIncome;
  final double netPnL;
  
  // Efficiency metrics
  final double pdEfficiency;
  
  // Related materials (not stored in DB, loaded separately)
  final List<BatchMaterial>? materials;

  ProductionBatch({
    String? id,
    required this.date,
    this.status = BatchStatus.draft,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.totalRawMaterials = 0,
    this.totalDerivedMaterials = 0,
    this.totalExpenses = 0,
    this.totalProductIncome = 0,
    this.totalByproductIncome = 0,
    this.totalIncome = 0,
    this.netPnL = 0,
    this.pdEfficiency = 0,
    this.materials,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ProductionBatch copyWith({
    String? id,
    DateTime? date,
    BatchStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalRawMaterials,
    double? totalDerivedMaterials,
    double? totalExpenses,
    double? totalProductIncome,
    double? totalByproductIncome,
    double? totalIncome,
    double? netPnL,
    double? pdEfficiency,
    List<BatchMaterial>? materials,
  }) {
    return ProductionBatch(
      id: id ?? this.id,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalRawMaterials: totalRawMaterials ?? this.totalRawMaterials,
      totalDerivedMaterials: totalDerivedMaterials ?? this.totalDerivedMaterials,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalProductIncome: totalProductIncome ?? this.totalProductIncome,
      totalByproductIncome: totalByproductIncome ?? this.totalByproductIncome,
      totalIncome: totalIncome ?? this.totalIncome,
      netPnL: netPnL ?? this.netPnL,
      pdEfficiency: pdEfficiency ?? this.pdEfficiency,
      materials: materials ?? this.materials,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': _dateToString(date),
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'total_raw_materials': totalRawMaterials,
      'total_derived_materials': totalDerivedMaterials,
      'total_expenses': totalExpenses,
      'total_product_income': totalProductIncome,
      'total_byproduct_income': totalByproductIncome,
      'total_income': totalIncome,
      'net_pnl': netPnL,
      'pd_efficiency': pdEfficiency,
    };
  }

  factory ProductionBatch.fromMap(Map<String, dynamic> map) {
    return ProductionBatch(
      id: map['id'],
      date: _dateFromString(map['date']),
      status: BatchStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BatchStatus.draft,
      ),
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      totalRawMaterials: map['total_raw_materials']?.toDouble() ?? 0,
      totalDerivedMaterials: map['total_derived_materials']?.toDouble() ?? 0,
      totalExpenses: map['total_expenses']?.toDouble() ?? 0,
      totalProductIncome: map['total_product_income']?.toDouble() ?? 0,
      totalByproductIncome: map['total_byproduct_income']?.toDouble() ?? 0,
      totalIncome: map['total_income']?.toDouble() ?? 0,
      netPnL: map['net_pnl']?.toDouble() ?? 0,
      pdEfficiency: map['pd_efficiency']?.toDouble() ?? 0,
    );
  }

  static String _dateToString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime _dateFromString(String dateString) {
    final parts = dateString.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  String toString() {
    return 'ProductionBatch(id: $id, date: $date, status: $status, netPnL: $netPnL, pdEfficiency: $pdEfficiency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductionBatch && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  String get statusDisplayName {
    switch (status) {
      case BatchStatus.draft:
        return 'Draft';
      case BatchStatus.completed:
        return 'Completed';
      case BatchStatus.archived:
        return 'Archived';
    }
  }

  String get dateDisplayString {
    return _dateToString(date);
  }

  bool get isDraft => status == BatchStatus.draft;
  bool get isCompleted => status == BatchStatus.completed;
  bool get isArchived => status == BatchStatus.archived;

  bool get isProfitable => netPnL > 0;
  bool get isLoss => netPnL < 0;
  bool get isBreakeven => netPnL == 0;

  double get profitMargin {
    if (totalIncome == 0) return 0;
    return (netPnL / totalIncome) * 100;
  }

  int get materialCount => materials?.length ?? 0;
  
  List<BatchMaterial> get rawMaterials {
    if (materials == null) return [];
    return materials!.where((m) => m.isRawMaterial).toList();
  }
  
  List<BatchMaterial> get derivedMaterials {
    if (materials == null) return [];
    return materials!.where((m) => m.isDerivedMaterial).toList();
  }
  
  List<BatchMaterial> get products {
    if (materials == null) return [];
    return materials!.where((m) => m.isProduct).toList();
  }
  
  List<BatchMaterial> get byproducts {
    if (materials == null) return [];
    return materials!.where((m) => m.isByproduct).toList();
  }
}