import '../models/material_template.dart';
import '../models/formula_dependency.dart';
import '../models/batch_material.dart';
import 'database_service.dart';

class MaterialTemplateService {
  static final DatabaseService _db = DatabaseService.instance;

  // Get all material templates
  static Future<List<MaterialTemplate>> getAllMaterials() async {
    return await _db.getAllMaterialTemplates();
  }

  // Get materials by category
  static Future<List<MaterialTemplate>> getMaterialsByCategory(MaterialCategory category) async {
    return await _db.getMaterialTemplatesByCategory(category);
  }

  // Get raw materials (base materials)
  static Future<List<MaterialTemplate>> getRawMaterials() async {
    return await getMaterialsByCategory(MaterialCategory.raw);
  }

  // Get derived materials
  static Future<List<MaterialTemplate>> getDerivedMaterials() async {
    return await getMaterialsByCategory(MaterialCategory.derived);
  }

  // Get products
  static Future<List<MaterialTemplate>> getProducts() async {
    return await getMaterialsByCategory(MaterialCategory.product);
  }

  // Get byproducts
  static Future<List<MaterialTemplate>> getByproducts() async {
    return await getMaterialsByCategory(MaterialCategory.byproduct);
  }

  // Get material by ID
  static Future<MaterialTemplate?> getMaterial(String id) async {
    return await _db.getMaterialTemplate(id);
  }

  // Create new material template
  static Future<String> createMaterial(MaterialTemplate template) async {
    // Validate the template
    final validationErrors = await validateMaterialTemplate(template);
    if (validationErrors.isNotEmpty) {
      throw Exception('Validation failed: ${validationErrors.join(', ')}');
    }

    // Insert the material template
    final id = await _db.insertMaterialTemplate(template);

    // If it's a derived material with a parent, create the formula dependency
    if (template.formulaType == FormulaType.multiplier && 
        template.parentMaterialId != null && 
        template.multiplier != null) {
      final dependency = FormulaDependency.multiplierDependency(
        materialId: template.id,
        dependsOnMaterialId: template.parentMaterialId!,
        multiplier: template.multiplier!,
      );
      await _db.insertFormulaDependency(dependency);
    }

    return id;
  }

  // Update material template
  static Future<void> updateMaterial(MaterialTemplate template) async {
    // Validate the template
    final validationErrors = await validateMaterialTemplate(template);
    if (validationErrors.isNotEmpty) {
      throw Exception('Validation failed: ${validationErrors.join(', ')}');
    }

    await _db.updateMaterialTemplate(template);

    // Update formula dependencies if needed
    if (template.formulaType == FormulaType.multiplier && 
        template.parentMaterialId != null && 
        template.multiplier != null) {
      
      // Get existing dependencies
      final existingDeps = await _db.getFormulaDependencies(template.id);
      
      if (existingDeps.isNotEmpty) {
        // Update existing dependency
        final updatedDep = existingDeps.first.copyWith(
          dependsOnMaterialId: template.parentMaterialId,
          multiplier: template.multiplier,
        );
        await _db.updateFormulaDependency(updatedDep);
      } else {
        // Create new dependency
        final dependency = FormulaDependency.multiplierDependency(
          materialId: template.id,
          dependsOnMaterialId: template.parentMaterialId!,
          multiplier: template.multiplier!,
        );
        await _db.insertFormulaDependency(dependency);
      }
    }
  }

  // Delete material template
  static Future<void> deleteMaterial(String id) async {
    // Check if material is used in any batches
    final allBatches = await _db.getAllProductionBatches();
    for (final batch in allBatches) {
      final materials = await _db.getBatchMaterials(batch.id);
      if (materials.any((m) => m.materialId == id)) {
        throw Exception('Cannot delete material: it is used in production batches');
      }
    }

    // Check if other materials depend on this one
    final allDependencies = await _db.getAllFormulaDependencies();
    if (allDependencies.any((d) => d.dependsOnMaterialId == id)) {
      throw Exception('Cannot delete material: other materials depend on it');
    }

    await _db.deleteMaterialTemplate(id);
  }

  // Validate material template
  static Future<List<String>> validateMaterialTemplate(MaterialTemplate template) async {
    final errors = <String>[];

    // Basic validation
    if (template.name.trim().isEmpty) {
      errors.add('Material name is required');
    }

    // Check for duplicate names (excluding current material)
    final existingMaterials = await getAllMaterials();
    if (existingMaterials.any((m) => m.name.toLowerCase() == template.name.toLowerCase() && m.id != template.id)) {
      errors.add('Material name already exists');
    }

    // Validate derived materials
    if (template.formulaType == FormulaType.multiplier) {
      if (template.parentMaterialId == null) {
        errors.add('Derived materials must have a parent material');
      } else if (template.parentMaterialId == template.id) {
        errors.add('Material cannot depend on itself');
      } else {
        // Check if parent exists
        final parent = await getMaterial(template.parentMaterialId!);
        if (parent == null) {
          errors.add('Parent material does not exist');
        }
      }

      if (template.multiplier == null || template.multiplier! <= 0) {
        errors.add('Multiplier must be greater than 0');
      }
    }

    // Validate manual materials
    if (template.formulaType == FormulaType.manual) {
      if (template.parentMaterialId != null) {
        errors.add('Manual materials cannot have a parent material');
      }
      if (template.multiplier != null) {
        errors.add('Manual materials cannot have a multiplier');
      }
    }

    return errors;
  }

  // Calculate derived material quantities
  static Future<Map<String, double>> calculateDerivedQuantities({
    required String baseMaterialId,
    required double baseQuantity,
  }) async {
    final quantities = <String, double>{baseMaterialId: baseQuantity};
    final allDependencies = await _db.getAllFormulaDependencies();
    
    // Build dependency tree
    final dependencyMap = <String, List<FormulaDependency>>{};
    for (final dep in allDependencies) {
      if (!dependencyMap.containsKey(dep.dependsOnMaterialId)) {
        dependencyMap[dep.dependsOnMaterialId] = [];
      }
      dependencyMap[dep.dependsOnMaterialId]!.add(dep);
    }

    // Calculate quantities recursively
    void calculateForMaterial(String materialId, double quantity) {
      quantities[materialId] = quantity;
      
      final dependencies = dependencyMap[materialId] ?? [];
      for (final dep in dependencies) {
        final derivedQuantity = dep.calculateResult(quantity);
        calculateForMaterial(dep.materialId, derivedQuantity);
      }
    }

    calculateForMaterial(baseMaterialId, baseQuantity);
    return quantities;
  }

  // Get material dependency chain
  static Future<List<MaterialTemplate>> getMaterialDependencyChain(String materialId) async {
    final chain = <MaterialTemplate>[];
    final visited = <String>{};

    Future<void> buildChain(String currentId) async {
      if (visited.contains(currentId)) return; // Prevent circular dependencies
      visited.add(currentId);

      final material = await getMaterial(currentId);
      if (material != null) {
        chain.add(material);
        
        if (material.parentMaterialId != null) {
          await buildChain(material.parentMaterialId!);
        }
      }
    }

    await buildChain(materialId);
    return chain.reversed.toList(); // Return in dependency order
  }

  // Get materials that depend on a given material
  static Future<List<MaterialTemplate>> getDependentMaterials(String materialId) async {
    final allDependencies = await _db.getAllFormulaDependencies();
    final dependentIds = allDependencies
        .where((dep) => dep.dependsOnMaterialId == materialId)
        .map((dep) => dep.materialId)
        .toList();

    final dependentMaterials = <MaterialTemplate>[];
    for (final id in dependentIds) {
      final material = await getMaterial(id);
      if (material != null) {
        dependentMaterials.add(material);
      }
    }

    return dependentMaterials;
  }

  // Create batch materials with calculated quantities
  static Future<List<BatchMaterial>> createBatchMaterials({
    required String batchId,
    required String baseMaterialId,
    required double baseQuantity,
    required double basePrice,
    required Map<String, double> materialPrices,
  }) async {
    final quantities = await calculateDerivedQuantities(
      baseMaterialId: baseMaterialId,
      baseQuantity: baseQuantity,
    );

    final batchMaterials = <BatchMaterial>[];
    int entryOrder = 0;

    for (final entry in quantities.entries) {
      final materialId = entry.key;
      final quantity = entry.value;
      final material = await getMaterial(materialId);
      
      if (material != null) {
        final price = materialId == baseMaterialId ? basePrice : (materialPrices[materialId] ?? 0);
        final isCalculated = materialId != baseMaterialId && material.isDerived;

        final batchMaterial = BatchMaterial(
          batchId: batchId,
          materialId: materialId,
          quantity: quantity,
          price: price,
          isCalculated: isCalculated,
          entryOrder: entryOrder++,
          materialTemplate: material,
        );

        batchMaterials.add(batchMaterial);
      }
    }

    return batchMaterials;
  }

  // Get material processing order (for UI workflow)
  static Future<List<MaterialTemplate>> getMaterialProcessingOrder() async {
    final allMaterials = await getAllMaterials();
    final processed = <MaterialTemplate>[];
    final visited = <String>{};

    // Add raw materials first
    final rawMaterials = allMaterials.where((m) => m.category == MaterialCategory.raw).toList();
    processed.addAll(rawMaterials);
    visited.addAll(rawMaterials.map((m) => m.id));

    // Add derived materials in dependency order
    while (processed.length < allMaterials.length) {
      final remaining = allMaterials.where((m) => !visited.contains(m.id)).toList();
      final added = <String>[];

      for (final material in remaining) {
        // Check if all dependencies are satisfied
        if (material.parentMaterialId == null || visited.contains(material.parentMaterialId)) {
          processed.add(material);
          visited.add(material.id);
          added.add(material.id);
        }
      }

      // Break if no progress (circular dependency or orphaned materials)
      if (added.isEmpty) break;
    }

    return processed;
  }

  // Get material statistics
  static Future<Map<String, dynamic>> getMaterialStatistics() async {
    final allMaterials = await getAllMaterials();
    
    return {
      'total_materials': allMaterials.length,
      'raw_materials': allMaterials.where((m) => m.category == MaterialCategory.raw).length,
      'derived_materials': allMaterials.where((m) => m.category == MaterialCategory.derived).length,
      'products': allMaterials.where((m) => m.category == MaterialCategory.product).length,
      'byproducts': allMaterials.where((m) => m.category == MaterialCategory.byproduct).length,
      'manual_entry': allMaterials.where((m) => m.formulaType == FormulaType.manual).length,
      'calculated': allMaterials.where((m) => m.formulaType != FormulaType.manual).length,
    };
  }
}