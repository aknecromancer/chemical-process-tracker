/// Supabase configuration for Chemical Process Tracker
/// This file contains the configuration for connecting to Supabase backend
class SupabaseConfig {
  // Private constructor to prevent instantiation
  SupabaseConfig._();

  /// Supabase URL - Replace with your actual Supabase project URL
  static const String supabaseUrl = 'https://your-project-id.supabase.co';

  /// Supabase Anonymous Key - Replace with your actual anon key
  static const String supabaseAnonKey = 'your-anon-key-here';

  /// Supabase Service Role Key - Replace with your actual service role key
  /// Warning: Keep this secure and never expose in client code
  static const String supabaseServiceRoleKey = 'your-service-role-key-here';

  /// Database configuration
  static const String databaseSchema = 'public';

  /// Table names
  static const String usersTable = 'users';
  static const String configurableDefaultsTable = 'configurable_defaults';
  static const String productionBatchesTable = 'production_batches';

  /// Connection settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration requestTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;

  /// Realtime settings
  static const bool enableRealtime = true;
  static const Duration realtimeHeartbeatInterval = Duration(seconds: 30);

  /// Offline settings
  static const bool enableOfflineMode = true;
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxOfflineEntries = 1000;

  /// Validation methods
  static bool isValidConfig() {
    return supabaseUrl.isNotEmpty &&
           supabaseAnonKey.isNotEmpty &&
           supabaseUrl != 'https://your-project-id.supabase.co' &&
           supabaseAnonKey != 'your-anon-key-here';
  }

  /// Get environment-specific configuration
  static Map<String, dynamic> getEnvironmentConfig() {
    return {
      'url': supabaseUrl,
      'anonKey': supabaseAnonKey,
      'timeout': connectionTimeout.inSeconds,
      'enableRealtime': enableRealtime,
      'enableOfflineMode': enableOfflineMode,
    };
  }
}

/// Development configuration (for testing)
class SupabaseDevConfig {
  static const String supabaseUrl = 'https://your-dev-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-dev-anon-key-here';
  static const bool enableLogging = true;
  static const bool enableDebugMode = true;
}

/// Production configuration
class SupabaseProdConfig {
  static const String supabaseUrl = 'https://your-prod-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-prod-anon-key-here';
  static const bool enableLogging = false;
  static const bool enableDebugMode = false;
}