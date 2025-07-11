import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/material_template.dart';
import '../models/production_batch.dart';
import '../models/batch_material.dart';
import '../models/formula_dependency.dart';
import '../models/price_history.dart';
import '../models/configurable_defaults.dart';
import 'database_web_initializer.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'chemical_process_tracker.db';
  static const int _databaseVersion = 1;

  // Singleton pattern
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize database factory for web/desktop platforms
    await DatabaseWebInitializer.initialize();
    
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create material_templates table
    await db.execute('''
      CREATE TABLE material_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        formula_type TEXT NOT NULL,
        multiplier REAL,
        parent_material_id TEXT,
        unit TEXT DEFAULT 'kg',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (parent_material_id) REFERENCES material_templates(id)
      )
    ''');

    // Create production_batches table
    await db.execute('''
      CREATE TABLE production_batches (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        status TEXT DEFAULT 'draft',
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        total_raw_materials REAL DEFAULT 0,
        total_derived_materials REAL DEFAULT 0,
        total_expenses REAL DEFAULT 0,
        total_product_income REAL DEFAULT 0,
        total_byproduct_income REAL DEFAULT 0,
        total_income REAL DEFAULT 0,
        net_pnl REAL DEFAULT 0,
        pd_efficiency REAL DEFAULT 0
      )
    ''');

    // Create batch_materials table
    await db.execute('''
      CREATE TABLE batch_materials (
        id TEXT PRIMARY KEY,
        batch_id TEXT NOT NULL,
        material_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        amount REAL NOT NULL,
        is_calculated INTEGER DEFAULT 0,
        entry_order INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (batch_id) REFERENCES production_batches(id) ON DELETE CASCADE,
        FOREIGN KEY (material_id) REFERENCES material_templates(id)
      )
    ''');

    // Create formula_dependencies table
    await db.execute('''
      CREATE TABLE formula_dependencies (
        id TEXT PRIMARY KEY,
        material_id TEXT NOT NULL,
        depends_on_material_id TEXT NOT NULL,
        multiplier REAL NOT NULL,
        operation TEXT DEFAULT 'multiply',
        sequence_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (material_id) REFERENCES material_templates(id),
        FOREIGN KEY (depends_on_material_id) REFERENCES material_templates(id)
      )
    ''');

    // Create price_history table
    await db.execute('''
      CREATE TABLE price_history (
        id TEXT PRIMARY KEY,
        material_id TEXT NOT NULL,
        price REAL NOT NULL,
        date TEXT NOT NULL,
        source TEXT DEFAULT 'manual',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (material_id) REFERENCES material_templates(id)
      )
    ''');

    // Create configurable_defaults table
    await db.execute('''
      CREATE TABLE configurable_defaults (
        id TEXT PRIMARY KEY,
        worker_fixed_amount REAL DEFAULT 38000,
        rent_fixed_amount REAL DEFAULT 25000,
        account_fixed_amount REAL DEFAULT 5000,
        fixed_denominator REAL DEFAULT 4500,
        cu_percentage REAL DEFAULT 0.10,
        tin_numerator REAL DEFAULT 11,
        tin_denominator REAL DEFAULT 30,
        default_pd_rate REAL DEFAULT 12000,
        default_cu_rate REAL DEFAULT 600,
        default_tin_rate REAL DEFAULT 38,
        default_other_rate REAL DEFAULT 4,
        default_nitric_rate REAL DEFAULT 26,
        default_hcl_rate REAL DEFAULT 1.7,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create app_settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        data_type TEXT DEFAULT 'string',
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for performance
    await _createIndexes(db);

    // Insert default material templates
    await _insertDefaultData(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_production_batches_date ON production_batches(date)');
    await db.execute('CREATE INDEX idx_batch_materials_batch_id ON batch_materials(batch_id)');
    await db.execute('CREATE INDEX idx_batch_materials_material_id ON batch_materials(material_id)');
    await db.execute('CREATE INDEX idx_formula_dependencies_material_id ON formula_dependencies(material_id)');
    await db.execute('CREATE INDEX idx_formula_dependencies_depends_on ON formula_dependencies(depends_on_material_id)');
    await db.execute('CREATE INDEX idx_price_history_material_date ON price_history(material_id, date)');
  }

  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Insert default material templates
    await db.insert('material_templates', {
      'id': 'patti',
      'name': 'Patti',
      'category': 'raw',
      'formula_type': 'manual',
      'multiplier': null,
      'parent_material_id': null,
      'unit': 'kg',
      'created_at': now,
      'updated_at': now,
      'is_active': 1,
    });

    await db.insert('material_templates', {
      'id': 'nitric',
      'name': 'Nitric',
      'category': 'derived',
      'formula_type': 'multiplier',
      'multiplier': 1.4,
      'parent_material_id': 'patti',
      'unit': 'kg',
      'created_at': now,
      'updated_at': now,
      'is_active': 1,
    });

    await db.insert('material_templates', {
      'id': 'hcl',
      'name': 'HCL',
      'category': 'derived',
      'formula_type': 'multiplier',
      'multiplier': 3.0,
      'parent_material_id': 'nitric',
      'unit': 'kg',
      'created_at': now,
      'updated_at': now,
      'is_active': 1,
    });

    await db.insert('material_templates', {
      'id': 'pd',
      'name': 'PD',
      'category': 'product',
      'formula_type': 'manual',
      'multiplier': null,
      'parent_material_id': null,
      'unit': 'kg',
      'created_at': now,
      'updated_at': now,
      'is_active': 1,
    });

    await db.insert('material_templates', {
      'id': 'cu',
      'name': 'CU',
      'category': 'byproduct',
      'formula_type': 'manual',
      'multiplier': null,
      'parent_material_id': null,
      'unit': 'kg',
      'created_at': now,
      'updated_at': now,
      'is_active': 1,
    });

    await db.insert('material_templates', {
      'id': 'tin',
      'name': 'TIN',
      'category': 'byproduct',
      'formula_type': 'manual',
      'multiplier': null,
      'parent_material_id': null,
      'unit': 'kg',
      'created_at': now,
      'updated_at': now,
      'is_active': 1,
    });

    // Insert formula dependencies
    await db.insert('formula_dependencies', {
      'id': 'dep1',
      'material_id': 'nitric',
      'depends_on_material_id': 'patti',
      'multiplier': 1.4,
      'operation': 'multiply',
      'sequence_order': 1,
      'is_active': 1,
    });

    await db.insert('formula_dependencies', {
      'id': 'dep2',
      'material_id': 'hcl',
      'depends_on_material_id': 'nitric',
      'multiplier': 3.0,
      'operation': 'multiply',
      'sequence_order': 2,
      'is_active': 1,
    });

    // Insert default configurable defaults
    await db.insert('configurable_defaults', {
      'id': 'default',
      'worker_fixed_amount': 38000,
      'rent_fixed_amount': 25000,
      'account_fixed_amount': 5000,
      'fixed_denominator': 4500,
      'cu_percentage': 0.10,
      'tin_numerator': 11,
      'tin_denominator': 30,
      'default_pd_rate': 12000,
      'default_cu_rate': 600,
      'default_tin_rate': 38,
      'default_other_rate': 4,
      'default_nitric_rate': 26,
      'default_hcl_rate': 1.7,
      'created_at': now,
      'updated_at': now,
    });

    // Insert default settings
    await db.insert('app_settings', {
      'key': 'currency',
      'value': '₹ INR',
      'data_type': 'string',
      'updated_at': now,
    });

    await db.insert('app_settings', {
      'key': 'default_unit',
      'value': 'kg',
      'data_type': 'string',
      'updated_at': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add upgrade logic here for future versions
    }
  }

  // Material Templates CRUD operations
  Future<List<MaterialTemplate>> getAllMaterialTemplates() async {
    final db = await database;
    final maps = await db.query(
      'material_templates',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => MaterialTemplate.fromMap(map)).toList();
  }

  Future<MaterialTemplate?> getMaterialTemplate(String id) async {
    final db = await database;
    final maps = await db.query(
      'material_templates',
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return MaterialTemplate.fromMap(maps.first);
    }
    return null;
  }

  Future<List<MaterialTemplate>> getMaterialTemplatesByCategory(MaterialCategory category) async {
    final db = await database;
    final maps = await db.query(
      'material_templates',
      where: 'category = ? AND is_active = ?',
      whereArgs: [category.name, 1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => MaterialTemplate.fromMap(map)).toList();
  }

  Future<String> insertMaterialTemplate(MaterialTemplate template) async {
    final db = await database;
    await db.insert('material_templates', template.toMap());
    return template.id;
  }

  Future<void> updateMaterialTemplate(MaterialTemplate template) async {
    final db = await database;
    await db.update(
      'material_templates',
      template.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<void> deleteMaterialTemplate(String id) async {
    final db = await database;
    await db.update(
      'material_templates',
      {'is_active': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Production Batches CRUD operations
  Future<List<ProductionBatch>> getAllProductionBatches() async {
    final db = await database;
    final maps = await db.query(
      'production_batches',
      orderBy: 'date DESC',
    );
    return maps.map((map) => ProductionBatch.fromMap(map)).toList();
  }

  Future<ProductionBatch?> getProductionBatch(String id) async {
    final db = await database;
    final maps = await db.query(
      'production_batches',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ProductionBatch.fromMap(maps.first);
    }
    return null;
  }

  Future<ProductionBatch?> getProductionBatchByDate(DateTime date) async {
    final db = await database;
    final dateString = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'production_batches',
      where: 'date = ?',
      whereArgs: [dateString],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ProductionBatch.fromMap(maps.first);
    }
    return null;
  }

  Future<String> insertProductionBatch(ProductionBatch batch) async {
    final db = await database;
    await db.insert('production_batches', batch.toMap());
    return batch.id;
  }

  Future<void> updateProductionBatch(ProductionBatch batch) async {
    final db = await database;
    await db.update(
      'production_batches',
      batch.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  Future<void> deleteProductionBatch(String id) async {
    final db = await database;
    await db.delete(
      'production_batches',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Batch Materials CRUD operations
  Future<List<BatchMaterial>> getBatchMaterials(String batchId) async {
    final db = await database;
    final maps = await db.query(
      'batch_materials',
      where: 'batch_id = ?',
      whereArgs: [batchId],
      orderBy: 'entry_order ASC, created_at ASC',
    );
    
    final materials = <BatchMaterial>[];
    for (final map in maps) {
      final material = BatchMaterial.fromMap(map);
      final template = await getMaterialTemplate(material.materialId);
      materials.add(material.copyWith(materialTemplate: template));
    }
    
    return materials;
  }

  Future<String> insertBatchMaterial(BatchMaterial material) async {
    final db = await database;
    await db.insert('batch_materials', material.toMap());
    return material.id;
  }

  Future<void> updateBatchMaterial(BatchMaterial material) async {
    final db = await database;
    await db.update(
      'batch_materials',
      material.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  Future<void> deleteBatchMaterial(String id) async {
    final db = await database;
    await db.delete(
      'batch_materials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Formula Dependencies CRUD operations
  Future<List<FormulaDependency>> getFormulaDependencies(String materialId) async {
    final db = await database;
    final maps = await db.query(
      'formula_dependencies',
      where: 'material_id = ? AND is_active = ?',
      whereArgs: [materialId, 1],
      orderBy: 'sequence_order ASC',
    );
    return maps.map((map) => FormulaDependency.fromMap(map)).toList();
  }

  Future<List<FormulaDependency>> getAllFormulaDependencies() async {
    final db = await database;
    final maps = await db.query(
      'formula_dependencies',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'sequence_order ASC',
    );
    return maps.map((map) => FormulaDependency.fromMap(map)).toList();
  }

  Future<String> insertFormulaDependency(FormulaDependency dependency) async {
    final db = await database;
    await db.insert('formula_dependencies', dependency.toMap());
    return dependency.id;
  }

  Future<void> updateFormulaDependency(FormulaDependency dependency) async {
    final db = await database;
    await db.update(
      'formula_dependencies',
      dependency.toMap(),
      where: 'id = ?',
      whereArgs: [dependency.id],
    );
  }

  Future<void> deleteFormulaDependency(String id) async {
    final db = await database;
    await db.update(
      'formula_dependencies',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Price History CRUD operations
  Future<List<PriceHistory>> getPriceHistory(String materialId, {int? limit}) async {
    final db = await database;
    final maps = await db.query(
      'price_history',
      where: 'material_id = ?',
      whereArgs: [materialId],
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
    );
    return maps.map((map) => PriceHistory.fromMap(map)).toList();
  }

  Future<PriceHistory?> getLatestPrice(String materialId) async {
    final prices = await getPriceHistory(materialId, limit: 1);
    return prices.isNotEmpty ? prices.first : null;
  }

  Future<String> insertPriceHistory(PriceHistory priceHistory) async {
    final db = await database;
    await db.insert('price_history', priceHistory.toMap());
    return priceHistory.id;
  }

  // Settings operations
  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<void> setSetting(String key, String value, {String dataType = 'string'}) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'data_type': dataType,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ConfigurableDefaults CRUD operations
  Future<ConfigurableDefaults> getConfigurableDefaults() async {
    final db = await database;
    final maps = await db.query(
      'configurable_defaults',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return ConfigurableDefaults.fromMap(maps.first);
    } else {
      // If no defaults exist, create and return default instance
      final defaults = ConfigurableDefaults.createDefault();
      await insertConfigurableDefaults(defaults);
      return defaults;
    }
  }

  Future<String> insertConfigurableDefaults(ConfigurableDefaults defaults) async {
    final db = await database;
    await db.insert('configurable_defaults', defaults.toMap());
    return defaults.id;
  }

  Future<void> updateConfigurableDefaults(ConfigurableDefaults defaults) async {
    final db = await database;
    final updatedDefaults = defaults.copyWith(updatedAt: DateTime.now());
    await db.update(
      'configurable_defaults',
      updatedDefaults.toMap(),
      where: 'id = ?',
      whereArgs: [defaults.id],
    );
  }

  Future<void> resetConfigurableDefaults() async {
    final db = await database;
    await db.delete('configurable_defaults');
    final defaults = ConfigurableDefaults.createDefault();
    await insertConfigurableDefaults(defaults);
  }

  // Utility methods
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> resetDatabase() async {
    await closeDatabase();
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    await deleteDatabase(path);
    _database = await _initDatabase();
  }
}