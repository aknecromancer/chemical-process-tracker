import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/supabase_config.dart';
import '../models/configurable_defaults.dart';
import '../models/production_batch.dart';

/// Supabase service for handling cloud database operations
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  // Private constructor
  SupabaseService._();

  /// Get singleton instance
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Initialize Supabase client
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Validate configuration
      if (!SupabaseConfig.isValidConfig()) {
        throw Exception('Invalid Supabase configuration. Please check your config file.');
      }

      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        debug: false, // Set to true for development
      );

      _client = Supabase.instance.client;
      _isInitialized = true;
      
      print('Supabase initialized successfully');
    } catch (e) {
      print('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  /// Get Supabase client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Check if online
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _isInitialized;

  /// Health check for Supabase connection
  Future<bool> healthCheck() async {
    try {
      if (!_isInitialized) return false;
      
      // Simple query to check connection
      final response = await client
          .from(SupabaseConfig.configurableDefaultsTable)
          .select('id')
          .limit(1);
      
      return response.isNotEmpty || response.isEmpty; // Both cases mean connection is working
    } catch (e) {
      print('Supabase health check failed: $e');
      return false;
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  /// Sign in anonymously (for now)
  Future<void> signInAnonymously() async {
    try {
      await client.auth.signInAnonymously();
    } catch (e) {
      print('Anonymous sign in failed: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      print('Sign out failed: $e');
      rethrow;
    }
  }

  /// Get defaults from Supabase
  Future<ConfigurableDefaults?> getDefaults() async {
    try {
      final response = await client
          .from(SupabaseConfig.configurableDefaultsTable)
          .select()
          .limit(1)
          .single();

      if (response.isNotEmpty) {
        return ConfigurableDefaults.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching defaults from Supabase: $e');
      return null;
    }
  }

  /// Save defaults to Supabase
  Future<void> saveDefaults(ConfigurableDefaults defaults) async {
    try {
      final json = defaults.toJson();
      
      // Add timestamp
      json['updated_at'] = DateTime.now().toIso8601String();
      
      // Use upsert to insert or update
      await client
          .from(SupabaseConfig.configurableDefaultsTable)
          .upsert(json);
    } catch (e) {
      print('Error saving defaults to Supabase: $e');
      rethrow;
    }
  }

  /// Get all batches from Supabase
  Future<List<ProductionBatch>> getAllBatches() async {
    try {
      final response = await client
          .from(SupabaseConfig.productionBatchesTable)
          .select()
          .order('batch_date', ascending: false);

      return response.map((json) => ProductionBatch.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching batches from Supabase: $e');
      return [];
    }
  }

  /// Get batch by date from Supabase
  Future<ProductionBatch?> getBatchByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0]; // Get date part only
      
      final response = await client
          .from(SupabaseConfig.productionBatchesTable)
          .select()
          .eq('batch_date', dateStr)
          .single();

      if (response.isNotEmpty) {
        return ProductionBatch.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching batch by date from Supabase: $e');
      return null;
    }
  }

  /// Save batch to Supabase
  Future<void> saveBatch(ProductionBatch batch) async {
    try {
      final json = batch.toJson();
      
      // Add timestamps
      json['batch_date'] = batch.date.toIso8601String().split('T')[0];
      json['updated_at'] = DateTime.now().toIso8601String();
      
      // Create unique identifier based on date
      json['id'] = 'batch_${batch.date.toIso8601String().split('T')[0]}';
      
      // Use upsert to insert or update
      await client
          .from(SupabaseConfig.productionBatchesTable)
          .upsert(json);
    } catch (e) {
      print('Error saving batch to Supabase: $e');
      rethrow;
    }
  }

  /// Update batch in Supabase
  Future<void> updateBatch(ProductionBatch batch) async {
    await saveBatch(batch); // Same operation for Supabase
  }

  /// Delete batch from Supabase
  Future<void> deleteBatch(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      
      await client
          .from(SupabaseConfig.productionBatchesTable)
          .delete()
          .eq('batch_date', dateStr);
    } catch (e) {
      print('Error deleting batch from Supabase: $e');
      rethrow;
    }
  }

  /// Get batches in date range
  Future<List<ProductionBatch>> getBatchesInRange(DateTime startDate, DateTime endDate) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];
      
      final response = await client
          .from(SupabaseConfig.productionBatchesTable)
          .select()
          .gte('batch_date', startDateStr)
          .lte('batch_date', endDateStr)
          .order('batch_date', ascending: false);

      return response.map((json) => ProductionBatch.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching batches in range from Supabase: $e');
      return [];
    }
  }

  /// Get recent batches (last N days)
  Future<List<ProductionBatch>> getRecentBatches(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getBatchesInRange(startDate, endDate);
  }

  /// Search batches by criteria
  Future<List<ProductionBatch>> searchBatches({
    String? status,
    double? minProfit,
    double? maxProfit,
    int? limit,
  }) async {
    try {
      var query = client
          .from(SupabaseConfig.productionBatchesTable)
          .select();

      // Apply filters based on criteria
      if (status != null) {
        // Filter by status - this would need to be implemented based on your business logic
        // For now, we'll skip this filter
      }

      if (minProfit != null) {
        // Filter by minimum profit - this would need to be implemented based on calculation_result
        // For now, we'll skip this filter
      }

      if (maxProfit != null) {
        // Filter by maximum profit - this would need to be implemented based on calculation_result
        // For now, we'll skip this filter
      }

      // Apply limit and ordering
      var finalQuery = query.order('batch_date', ascending: false);
      
      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;
      return response.map((json) => ProductionBatch.fromJson(json)).toList();
    } catch (e) {
      print('Error searching batches in Supabase: $e');
      return [];
    }
  }

  /// Clear all data (for testing purposes)
  Future<void> clearAllData() async {
    try {
      await client
          .from(SupabaseConfig.productionBatchesTable)
          .delete()
          .neq('id', 'non-existent-id'); // Delete all records
      
      await client
          .from(SupabaseConfig.configurableDefaultsTable)
          .delete()
          .neq('id', 'non-existent-id'); // Delete all records
    } catch (e) {
      print('Error clearing data from Supabase: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time changes
  RealtimeChannel subscribeToChanges({
    required String table,
    required void Function(Map<String, dynamic>) onInsert,
    required void Function(Map<String, dynamic>) onUpdate,
    required void Function(Map<String, dynamic>) onDelete,
  }) {
    return client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          callback: (payload) {
            if (payload.newRecord != null) {
              onInsert(payload.newRecord!);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: table,
          callback: (payload) {
            if (payload.newRecord != null) {
              onUpdate(payload.newRecord!);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: table,
          callback: (payload) {
            if (payload.oldRecord != null) {
              onDelete(payload.oldRecord!);
            }
          },
        )
        .subscribe();
  }

  /// Dispose resources
  void dispose() {
    _client?.dispose();
    _client = null;
    _isInitialized = false;
    _instance = null;
  }
}