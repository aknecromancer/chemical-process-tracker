import 'package:uuid/uuid.dart';

enum PriceSource {
  manual,
  import,
  api,
}

class PriceHistory {
  final String id;
  final String materialId;
  final double price;
  final DateTime date;
  final PriceSource source;
  final DateTime createdAt;

  PriceHistory({
    String? id,
    required this.materialId,
    required this.price,
    required this.date,
    this.source = PriceSource.manual,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  PriceHistory copyWith({
    String? id,
    String? materialId,
    double? price,
    DateTime? date,
    PriceSource? source,
    DateTime? createdAt,
  }) {
    return PriceHistory(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      price: price ?? this.price,
      date: date ?? this.date,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'material_id': materialId,
      'price': price,
      'date': _dateToString(date),
      'source': source.name,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PriceHistory.fromMap(Map<String, dynamic> map) {
    return PriceHistory(
      id: map['id'],
      materialId: map['material_id'],
      price: map['price']?.toDouble() ?? 0,
      date: _dateFromString(map['date']),
      source: PriceSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => PriceSource.manual,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
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
    return 'PriceHistory(id: $id, materialId: $materialId, price: $price, date: $date, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PriceHistory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  String get dateDisplayString {
    return _dateToString(date);
  }

  String get priceDisplayString {
    return '₹${price.toStringAsFixed(2)}';
  }

  String get sourceDisplayName {
    switch (source) {
      case PriceSource.manual:
        return 'Manual Entry';
      case PriceSource.import:
        return 'Data Import';
      case PriceSource.api:
        return 'API Feed';
    }
  }

  bool get isManualEntry => source == PriceSource.manual;
  bool get isImported => source == PriceSource.import;
  bool get isFromApi => source == PriceSource.api;

  // Helper methods for price analysis
  bool isHigherThan(double comparePrice) => price > comparePrice;
  bool isLowerThan(double comparePrice) => price < comparePrice;
  
  double percentageChangeFrom(double basePrice) {
    if (basePrice == 0) return 0;
    return ((price - basePrice) / basePrice) * 100;
  }

  bool isWithinRange(double minPrice, double maxPrice) {
    return price >= minPrice && price <= maxPrice;
  }

  Duration daysSince(DateTime compareDate) {
    return date.difference(compareDate);
  }

  bool isRecent(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return date.isAfter(cutoffDate);
  }
}