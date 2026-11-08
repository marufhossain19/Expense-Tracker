/// Configuration file for external API keys and service URLs.
/// Sensitive credentials are read from environment variables or configured via .env.
library;

class AppConfig {
  // ── Supabase ──────────────────────────────────────────────
  /// Supabase project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );

  /// Supabase anon/public key (JWT format)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  // ── OpenWeather API ───────────────────────────────────────
  /// OpenWeatherMap API key
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: 'YOUR_OPENWEATHER_API_KEY',
  );

  /// Base URL for OpenWeather API
  static const String openWeatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  // ── Feature Flags ─────────────────────────────────────────
  /// Set to true once Supabase credentials are configured
  static bool get isSupabaseEnabled =>
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;

  /// Set to true once OpenWeather API key is configured
  static bool get isWeatherEnabled =>
      openWeatherApiKey != 'YOUR_OPENWEATHER_API_KEY' &&
      openWeatherApiKey.isNotEmpty;
}
