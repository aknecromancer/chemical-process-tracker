import 'package:uuid/uuid.dart';
import 'material_template.dart';

class BatchMaterial {
  final String id;
  final String batchId;
  final String materialId;
  final double quantity;
  final double price;
  final double amount;
  final bool isCalculated;
  final int entryOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related material template (not stored in DB, loaded separately)
  final MaterialTemplate? materialTemplate;

  BatchMaterial({
    String? id,
    required this.batchId,
    required this.materialId,
    required this.quantity,
    required this.price,
    double? amount,
    this.isCalculated = false,
    this.entryOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.materialTemplate,
  })  : id = id ?? const Uuid().v4(),
        amount = amount ?? (quantity * price),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  BatchMaterial copyWith({
    String? id,
    String? batchId,
    String? materialId,
    double? quantity,
    double? price,
    double? amount,
    bool? isCalculated,
    int? entryOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    MaterialTemplate? materialTemplate,
  }) {
    return BatchMaterial(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      materialId: materialId ?? this.materialId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      amount: amount ?? this.amount,
      isCalculated: isCalculated ?? this.isCalculated,
      entryOrder: entryOrder ?? this.entryOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      materialTemplate: materialTemplate ?? this.materialTemplate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batch_id': batchId,
      'material_id': materialId,
      'quantity': quantity,
      'price': price,
      'amount': amount,
      'is_calculated': isCalculated ? 1 : 0,
      'entry_order': entryOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory BatchMaterial.fromMap(Map<String, dynamic> map) {
    return BatchMaterial(
      id: map['id'],
      batchId: map['batch_id'],
      materialId: map['material_id'],
      quantity: map['quantity']?.toDouble() ?? 0,
      price: map['price']?.toDouble() ?? 0,
      amount: map['amount']?.toDouble() ?? 0,
      isCalculated: map['is_calculated'] == 1,
      entryOrder: map['entry_order'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'BatchMaterial(id: $id, materialId: $materialId, quantity: $quantity, price: $price, amount: $amount, isCalculated: $isCalculated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatchMaterial && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  String get materialName => materialTemplate?.name ?? 'Unknown Material';
  String get materialUnit => materialTemplate?.unit ?? 'kg';
  MaterialCategory? get materialCategory => materialTemplate?.category;

  bool get isRawMaterial => materialCategory == MaterialCategory.raw;
  bool get isDerivedMaterial => materialCategory == MaterialCategory.derived;
  bool get isProduct => materialCategory == MaterialCategory.product;
  bool get isByproduct => materialCategory == MaterialCategory.byproduct;

  bool get isIncome => isProduct || isByproduct;
  bool get isExpense => isRawMaterial || isDerivedMaterial;

  double get pricePerUnit => price;
  double get totalValue => amount;

  String get quantityDisplayString {
    return '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} $materialUnit';
  }

  String get priceDisplayString {
    return '₹${price.toStringAsFixed(2)}/$materialUnit';
  }

  String get amountDisplayString {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String get calculationDisplayString {
    return '$quantityDisplayString × ₹${price.toStringAsFixed(2)} = $amountDisplayString';
  }

  String get entryTypeDisplayString {
    return isCalculated ? 'Auto-calculated' : 'Manual entry';
  }

  // Validation methods
  bool get isValid {
    return quantity > 0 && price >= 0 && materialId.isNotEmpty && batchId.isNotEmpty;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (quantity <= 0) {
      errors.add('Quantity must be greater than 0');
    }
    
    if (price < 0) {
      errors.add('Price cannot be negative');
    }
    
    if (materialId.isEmpty) {
      errors.add('Material must be selected');
    }
    
    if (batchId.isEmpty) {
      errors.add('Batch ID is required');
    }
    
    return errors;
  }

  // Factory methods for creating specific types
  factory BatchMaterial.rawMaterial({
    required String batchId,
    required String materialId,
    required double quantity,
    required double price,
    int entryOrder = 0,
    MaterialTemplate? materialTemplate,
  }) {
    return BatchMaterial(
      batchId: batchId,
      materialId: materialId,
      quantity: quantity,
      price: price,
      isCalculated: false,
      entryOrder: entryOrder,
      materialTemplate: materialTemplate,
    );
  }

  factory BatchMaterial.derivedMaterial({
    required String batchId,
    required String materialId,
    required double quantity,
    required double price,
    int entryOrder = 0,
    MaterialTemplate? materialTemplate,
  }) {
    return BatchMaterial(
      batchId: batchId,
      materialId: materialId,
      quantity: quantity,
      price: price,
      isCalculated: true,
      entryOrder: entryOrder,
      materialTemplate: materialTemplate,
    );
  }

  factory BatchMaterial.product({
    required String batchId,
    required String materialId,
    required double quantity,
    required double price,
    int entryOrder = 0,
    MaterialTemplate? materialTemplate,
  }) {
    return BatchMaterial(
      batchId: batchId,
      materialId: materialId,
      quantity: quantity,
      price: price,
      isCalculated: false,
      entryOrder: entryOrder,
      materialTemplate: materialTemplate,
    );
  }

  factory BatchMaterial.byproduct({
    required String batchId,
    required String materialId,
    required double quantity,
    required double price,
    int entryOrder = 0,
    MaterialTemplate? materialTemplate,
  }) {
    return BatchMaterial(
      batchId: batchId,
      materialId: materialId,
      quantity: quantity,
      price: price,
      isCalculated: false,
      entryOrder: entryOrder,
      materialTemplate: materialTemplate,
    );
  }
}