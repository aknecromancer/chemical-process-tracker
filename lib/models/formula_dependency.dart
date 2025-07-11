import 'package:uuid/uuid.dart';

enum FormulaOperation {
  multiply,
  add,
  subtract,
  divide,
}

class FormulaDependency {
  final String id;
  final String materialId;
  final String dependsOnMaterialId;
  final double multiplier;
  final FormulaOperation operation;
  final int sequenceOrder;
  final bool isActive;

  FormulaDependency({
    String? id,
    required this.materialId,
    required this.dependsOnMaterialId,
    required this.multiplier,
    this.operation = FormulaOperation.multiply,
    this.sequenceOrder = 0,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  FormulaDependency copyWith({
    String? id,
    String? materialId,
    String? dependsOnMaterialId,
    double? multiplier,
    FormulaOperation? operation,
    int? sequenceOrder,
    bool? isActive,
  }) {
    return FormulaDependency(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      dependsOnMaterialId: dependsOnMaterialId ?? this.dependsOnMaterialId,
      multiplier: multiplier ?? this.multiplier,
      operation: operation ?? this.operation,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'material_id': materialId,
      'depends_on_material_id': dependsOnMaterialId,
      'multiplier': multiplier,
      'operation': operation.name,
      'sequence_order': sequenceOrder,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory FormulaDependency.fromMap(Map<String, dynamic> map) {
    return FormulaDependency(
      id: map['id'],
      materialId: map['material_id'],
      dependsOnMaterialId: map['depends_on_material_id'],
      multiplier: map['multiplier']?.toDouble() ?? 1.0,
      operation: FormulaOperation.values.firstWhere(
        (e) => e.name == map['operation'],
        orElse: () => FormulaOperation.multiply,
      ),
      sequenceOrder: map['sequence_order'] ?? 0,
      isActive: map['is_active'] == 1,
    );
  }

  @override
  String toString() {
    return 'FormulaDependency(id: $id, materialId: $materialId, dependsOnMaterialId: $dependsOnMaterialId, multiplier: $multiplier, operation: $operation)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormulaDependency && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  String get operationDisplayName {
    switch (operation) {
      case FormulaOperation.multiply:
        return 'Multiply by';
      case FormulaOperation.add:
        return 'Add';
      case FormulaOperation.subtract:
        return 'Subtract';
      case FormulaOperation.divide:
        return 'Divide by';
    }
  }

  String get operationSymbol {
    switch (operation) {
      case FormulaOperation.multiply:
        return '×';
      case FormulaOperation.add:
        return '+';
      case FormulaOperation.subtract:
        return '-';
      case FormulaOperation.divide:
        return '÷';
    }
  }

  String get formulaDisplayString {
    return '$operationSymbol $multiplier';
  }

  // Calculate the result based on the input value
  double calculateResult(double inputValue) {
    switch (operation) {
      case FormulaOperation.multiply:
        return inputValue * multiplier;
      case FormulaOperation.add:
        return inputValue + multiplier;
      case FormulaOperation.subtract:
        return inputValue - multiplier;
      case FormulaOperation.divide:
        return multiplier != 0 ? inputValue / multiplier : 0;
    }
  }

  // Validation methods
  bool get isValid {
    return materialId.isNotEmpty && 
           dependsOnMaterialId.isNotEmpty && 
           materialId != dependsOnMaterialId &&
           (operation != FormulaOperation.divide || multiplier != 0);
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (materialId.isEmpty) {
      errors.add('Material ID is required');
    }
    
    if (dependsOnMaterialId.isEmpty) {
      errors.add('Dependency material ID is required');
    }
    
    if (materialId == dependsOnMaterialId) {
      errors.add('Material cannot depend on itself');
    }
    
    if (operation == FormulaOperation.divide && multiplier == 0) {
      errors.add('Cannot divide by zero');
    }
    
    return errors;
  }

  bool get isMultiplication => operation == FormulaOperation.multiply;
  bool get isAddition => operation == FormulaOperation.add;
  bool get isSubtraction => operation == FormulaOperation.subtract;
  bool get isDivision => operation == FormulaOperation.divide;

  // Factory methods for common dependency types
  factory FormulaDependency.multiplierDependency({
    required String materialId,
    required String dependsOnMaterialId,
    required double multiplier,
    int sequenceOrder = 0,
  }) {
    return FormulaDependency(
      materialId: materialId,
      dependsOnMaterialId: dependsOnMaterialId,
      multiplier: multiplier,
      operation: FormulaOperation.multiply,
      sequenceOrder: sequenceOrder,
    );
  }

  factory FormulaDependency.additiveDependency({
    required String materialId,
    required String dependsOnMaterialId,
    required double addValue,
    int sequenceOrder = 0,
  }) {
    return FormulaDependency(
      materialId: materialId,
      dependsOnMaterialId: dependsOnMaterialId,
      multiplier: addValue,
      operation: FormulaOperation.add,
      sequenceOrder: sequenceOrder,
    );
  }
}