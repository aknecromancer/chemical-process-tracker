import 'package:uuid/uuid.dart';

enum FormulaType {
  manual,
  multiplier,
  custom,
}

enum MaterialCategory {
  raw,
  derived,
  product,
  byproduct,
}

class MaterialTemplate {
  final String id;
  final String name;
  final MaterialCategory category;
  final FormulaType formulaType;
  final double? multiplier;
  final String? parentMaterialId;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  MaterialTemplate({
    String? id,
    required this.name,
    required this.category,
    required this.formulaType,
    this.multiplier,
    this.parentMaterialId,
    this.unit = 'kg',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  MaterialTemplate copyWith({
    String? id,
    String? name,
    MaterialCategory? category,
    FormulaType? formulaType,
    double? multiplier,
    String? parentMaterialId,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return MaterialTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      formulaType: formulaType ?? this.formulaType,
      multiplier: multiplier ?? this.multiplier,
      parentMaterialId: parentMaterialId ?? this.parentMaterialId,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'formula_type': formulaType.name,
      'multiplier': multiplier,
      'parent_material_id': parentMaterialId,
      'unit': unit,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory MaterialTemplate.fromMap(Map<String, dynamic> map) {
    return MaterialTemplate(
      id: map['id'],
      name: map['name'],
      category: MaterialCategory.values.firstWhere(
        (e) => e.name == map['category'],
      ),
      formulaType: FormulaType.values.firstWhere(
        (e) => e.name == map['formula_type'],
      ),
      multiplier: map['multiplier']?.toDouble(),
      parentMaterialId: map['parent_material_id'],
      unit: map['unit'] ?? 'kg',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isActive: map['is_active'] == 1,
    );
  }

  @override
  String toString() {
    return 'MaterialTemplate(id: $id, name: $name, category: $category, formulaType: $formulaType, multiplier: $multiplier, parentMaterialId: $parentMaterialId, unit: $unit, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  bool get isManualEntry => formulaType == FormulaType.manual;
  bool get isDerived => formulaType != FormulaType.manual;
  bool get hasParent => parentMaterialId != null;
  
  String get categoryDisplayName {
    switch (category) {
      case MaterialCategory.raw:
        return 'Raw Material';
      case MaterialCategory.derived:
        return 'Derived Material';
      case MaterialCategory.product:
        return 'Product';
      case MaterialCategory.byproduct:
        return 'Byproduct';
    }
  }

  String get formulaTypeDisplayName {
    switch (formulaType) {
      case FormulaType.manual:
        return 'Manual Entry';
      case FormulaType.multiplier:
        return 'Multiplier Formula';
      case FormulaType.custom:
        return 'Custom Formula';
    }
  }
}