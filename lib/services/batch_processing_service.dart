import '../models/production_batch.dart';
import '../models/batch_material.dart';
import '../models/material_template.dart';
import '../models/price_history.dart';
import 'database_service.dart';
import 'material_template_service.dart';

class BatchProcessingService {
  static final DatabaseService _db = DatabaseService.instance;

  // Create a new production batch
  static Future<ProductionBatch> createBatch(DateTime date) async {
    // Check if batch already exists for this date
    final existing = await _db.getProductionBatchByDate(date);
    if (existing != null) {
      throw Exception('A batch already exists for ${existing.dateDisplayString}');
    }

    final batch = ProductionBatch(date: date);
    await _db.insertProductionBatch(batch);
    return batch;
  }

  // Get batch by date
  static Future<ProductionBatch?> getBatchByDate(DateTime date) async {
    return await _db.getProductionBatchByDate(date);
  }

  // Get batch with materials
  static Future<ProductionBatch?> getBatchWithMaterials(String batchId) async {
    final batch = await _db.getProductionBatch(batchId);
    if (batch == null) return null;

    final materials = await _db.getBatchMaterials(batchId);
    return batch.copyWith(materials: materials);
  }

  // Get all batches
  static Future<List<ProductionBatch>> getAllBatches() async {
    return await _db.getAllProductionBatches();
  }

  // Add base material to batch
  static Future<void> addBaseMaterial({
    required String batchId,
    required String materialId,
    required double quantity,
    required double price,
  }) async {
    // Validate inputs
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }
    if (price < 0) {
      throw Exception('Price cannot be negative');
    }

    // Get material template
    final material = await MaterialTemplateService.getMaterial(materialId);
    if (material == null) {
      throw Exception('Material not found');
    }

    if (material.category != MaterialCategory.raw) {
      throw Exception('Only raw materials can be added as base materials');
    }

    // Create batch material
    final batchMaterial = BatchMaterial.rawMaterial(
      batchId: batchId,
      materialId: materialId,
      quantity: quantity,
      price: price,
      materialTemplate: material,
    );

    await _db.insertBatchMaterial(batchMaterial);

    // Calculate and add derived materials
    await _calculateAndAddDerivedMaterials(batchId, materialId, quantity);

    // Save price history
    await _savePriceHistory(materialId, price, DateTime.now());

    // Update batch totals
    await _updateBatchTotals(batchId);
  }

  // Add derived material price
  static Future<void> addDerivedMaterialPrice({
    required String batchId,
    required String materialId,
    required double price,
  }) async {
    if (price < 0) {
      throw Exception('Price cannot be negative');
    }

    // Get existing batch materials
    final materials = await _db.getBatchMaterials(batchId);
    final existingMaterial = materials.where((m) => m.materialId == materialId).firstOrNull;

    if (existingMaterial == null) {
      throw Exception('Material not found in batch');
    }

    // Update the price
    final updatedMaterial = existingMaterial.copyWith(price: price);
    await _db.updateBatchMaterial(updatedMaterial);

    // Save price history
    await _savePriceHistory(materialId, price, DateTime.now());

    // Update batch totals
    await _updateBatchTotals(batchId);
  }

  // Add product to batch
  static Future<void> addProduct({
    required String batchId,
    required String materialId,
    required double quantity,
    required double price,
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }
    if (price < 0) {
      throw Exception('Price cannot be negative');
    }

    final material = await MaterialTemplateService.getMaterial(materialId);
    if (material == null) {
      throw Exception('Material not found');
    }

    if (material.category != MaterialCategory.product) {
      throw Exception('Only products can be added as products');
    }

    final batchMaterial = BatchMaterial.product(
      batchId: batchId,
      materialId: materialId,
      quantity: quantity,
      price: price,
      materialTemplate: material,
    );

    await _db.insertBatchMaterial(batchMaterial);
    await _savePriceHistory(materialId, price, DateTime.now());
    await _updateBatchTotals(batchId);
  }

  // Add byproduct to batch
  static Future<void> addByproduct({
    required String batchId,
    required String materialId,
    required double quantity,
    required double price,
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }
    if (price < 0) {
      throw Exception('Price cannot be negative');
    }

    final material = await MaterialTemplateService.getMaterial(materialId);
    if (material == null) {
      throw Exception('Material not found');
    }

    if (material.category != MaterialCategory.byproduct) {
      throw Exception('Only byproducts can be added as byproducts');
    }

    final batchMaterial = BatchMaterial.byproduct(
      batchId: batchId,
      materialId: materialId,
      quantity: quantity,
      price: price,
      materialTemplate: material,
    );

    await _db.insertBatchMaterial(batchMaterial);
    await _savePriceHistory(materialId, price, DateTime.now());
    await _updateBatchTotals(batchId);
  }

  // Calculate and add derived materials
  static Future<void> _calculateAndAddDerivedMaterials(
    String batchId,
    String baseMaterialId,
    double baseQuantity,
  ) async {
    final quantities = await MaterialTemplateService.calculateDerivedQuantities(
      baseMaterialId: baseMaterialId,
      baseQuantity: baseQuantity,
    );

    for (final entry in quantities.entries) {
      final materialId = entry.key;
      final quantity = entry.value;

      // Skip the base material (already added)
      if (materialId == baseMaterialId) continue;

      final material = await MaterialTemplateService.getMaterial(materialId);
      if (material != null && material.category == MaterialCategory.derived) {
        // Get latest price or use 0 as placeholder
        final latestPrice = await _db.getLatestPrice(materialId);
        final price = latestPrice?.price ?? 0;

        final batchMaterial = BatchMaterial.derivedMaterial(
          batchId: batchId,
          materialId: materialId,
          quantity: quantity,
          price: price,
          materialTemplate: material,
        );

        await _db.insertBatchMaterial(batchMaterial);
      }
    }
  }

  // Update batch totals and calculations
  static Future<void> _updateBatchTotals(String batchId) async {
    final materials = await _db.getBatchMaterials(batchId);
    
    double totalRawMaterials = 0;
    double totalDerivedMaterials = 0;
    double totalProductIncome = 0;
    double totalByproductIncome = 0;
    double pdEfficiency = 0;

    double pattiQuantity = 0;
    double pdQuantity = 0;

    for (final material in materials) {
      switch (material.materialCategory) {
        case MaterialCategory.raw:
          totalRawMaterials += material.amount;
          if (material.materialTemplate?.name.toLowerCase() == 'patti') {
            pattiQuantity = material.quantity;
          }
          break;
        case MaterialCategory.derived:
          totalDerivedMaterials += material.amount;
          break;
        case MaterialCategory.product:
          totalProductIncome += material.amount;
          if (material.materialTemplate?.name.toLowerCase() == 'pd') {
            pdQuantity = material.quantity;
          }
          break;
        case MaterialCategory.byproduct:
          totalByproductIncome += material.amount;
          break;
        case null:
          break;
      }
    }

    // Calculate PD efficiency
    if (pattiQuantity > 0 && pdQuantity > 0) {
      pdEfficiency = (pdQuantity / pattiQuantity) * 100;
    }

    final totalExpenses = totalRawMaterials + totalDerivedMaterials;
    final totalIncome = totalProductIncome + totalByproductIncome;
    final netPnL = totalIncome - totalExpenses;

    // Update batch
    final batch = await _db.getProductionBatch(batchId);
    if (batch != null) {
      final updatedBatch = batch.copyWith(
        totalRawMaterials: totalRawMaterials,
        totalDerivedMaterials: totalDerivedMaterials,
        totalExpenses: totalExpenses,
        totalProductIncome: totalProductIncome,
        totalByproductIncome: totalByproductIncome,
        totalIncome: totalIncome,
        netPnL: netPnL,
        pdEfficiency: pdEfficiency,
      );
      await _db.updateProductionBatch(updatedBatch);
    }
  }

  // Save price history
  static Future<void> _savePriceHistory(String materialId, double price, DateTime date) async {
    final priceHistory = PriceHistory(
      materialId: materialId,
      price: price,
      date: date,
      source: PriceSource.manual,
    );
    await _db.insertPriceHistory(priceHistory);
  }

  // Complete batch
  static Future<void> completeBatch(String batchId) async {
    final batch = await _db.getProductionBatch(batchId);
    if (batch == null) {
      throw Exception('Batch not found');
    }

    // Validate batch completeness
    final materials = await _db.getBatchMaterials(batchId);
    final validationErrors = _validateBatchCompleteness(materials);
    if (validationErrors.isNotEmpty) {
      throw Exception('Batch validation failed: ${validationErrors.join(', ')}');
    }

    final completedBatch = batch.copyWith(status: BatchStatus.completed);
    await _db.updateProductionBatch(completedBatch);
  }

  // Validate batch completeness
  static List<String> _validateBatchCompleteness(List<BatchMaterial> materials) {
    final errors = <String>[];

    if (materials.isEmpty) {
      errors.add('Batch has no materials');
      return errors;
    }

    // Check for zero prices
    final zeroPrice = materials.where((m) => m.price == 0).toList();
    if (zeroPrice.isNotEmpty) {
      errors.add('Some materials have zero price: ${zeroPrice.map((m) => m.materialName).join(', ')}');
    }

    // Check for negative quantities
    final negativeQty = materials.where((m) => m.quantity <= 0).toList();
    if (negativeQty.isNotEmpty) {
      errors.add('Some materials have invalid quantities: ${negativeQty.map((m) => m.materialName).join(', ')}');
    }

    return errors;
  }

  // Delete batch material
  static Future<void> deleteBatchMaterial(String materialId) async {
    await _db.deleteBatchMaterial(materialId);
  }

  // Update batch material
  static Future<void> updateBatchMaterial(BatchMaterial material) async {
    await _db.updateBatchMaterial(material);
    await _updateBatchTotals(material.batchId);
  }

  // Get price suggestions
  static Future<List<double>> getPriceSuggestions(String materialId, {int limit = 5}) async {
    final priceHistory = await _db.getPriceHistory(materialId, limit: limit);
    return priceHistory.map((p) => p.price).toList();
  }

  // Get batch statistics
  static Future<Map<String, dynamic>> getBatchStatistics(String batchId) async {
    final batch = await getBatchWithMaterials(batchId);
    if (batch == null) return {};

    final materials = batch.materials ?? [];
    
    return {
      'total_materials': materials.length,
      'raw_materials_count': materials.where((m) => m.isRawMaterial).length,
      'derived_materials_count': materials.where((m) => m.isDerivedMaterial).length,
      'products_count': materials.where((m) => m.isProduct).length,
      'byproducts_count': materials.where((m) => m.isByproduct).length,
      'total_expenses': batch.totalExpenses,
      'total_income': batch.totalIncome,
      'net_pnl': batch.netPnL,
      'pd_efficiency': batch.pdEfficiency,
      'profit_margin': batch.profitMargin,
      'is_profitable': batch.isProfitable,
    };
  }

  // Clone batch to new date
  static Future<ProductionBatch> cloneBatch(String sourceBatchId, DateTime newDate) async {
    final sourceBatch = await getBatchWithMaterials(sourceBatchId);
    if (sourceBatch == null) {
      throw Exception('Source batch not found');
    }

    // Create new batch
    final newBatch = await createBatch(newDate);
    
    // Copy materials (without prices, they need to be re-entered)
    final sourceMaterials = sourceBatch.materials ?? [];
    for (final material in sourceMaterials) {
      if (material.isRawMaterial || material.isProduct || material.isByproduct) {
        // Only copy manual entry materials, derived will be calculated automatically
        final newMaterial = BatchMaterial(
          batchId: newBatch.id,
          materialId: material.materialId,
          quantity: material.quantity,
          price: 0, // Reset price
          isCalculated: false,
          materialTemplate: material.materialTemplate,
        );
        await _db.insertBatchMaterial(newMaterial);
      }
    }

    return newBatch;
  }

  // Get processing workflow for batch
  static Future<List<Map<String, dynamic>>> getBatchWorkflow(String batchId) async {
    final materials = await _db.getBatchMaterials(batchId);
    final workflow = <Map<String, dynamic>>[];

    // Group by processing order
    final rawMaterials = materials.where((m) => m.isRawMaterial).toList();
    final derivedMaterials = materials.where((m) => m.isDerivedMaterial).toList();
    final products = materials.where((m) => m.isProduct).toList();
    final byproducts = materials.where((m) => m.isByproduct).toList();

    if (rawMaterials.isNotEmpty) {
      workflow.add({
        'phase': 'Phase 1: Raw Materials',
        'description': 'Base materials for processing',
        'materials': rawMaterials,
        'completed': rawMaterials.every((m) => m.price > 0),
      });
    }

    if (derivedMaterials.isNotEmpty) {
      workflow.add({
        'phase': 'Phase 2: Derived Materials',
        'description': 'Materials calculated from base materials',
        'materials': derivedMaterials,
        'completed': derivedMaterials.every((m) => m.price > 0),
      });
    }

    if (products.isNotEmpty) {
      workflow.add({
        'phase': 'Phase 3: Products',
        'description': 'Primary products from processing',
        'materials': products,
        'completed': products.every((m) => m.price > 0),
      });
    }

    if (byproducts.isNotEmpty) {
      workflow.add({
        'phase': 'Phase 4: Byproducts',
        'description': 'Secondary products from processing',
        'materials': byproducts,
        'completed': byproducts.every((m) => m.price > 0),
      });
    }

    return workflow;
  }
}