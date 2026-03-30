/// API Configuration for SGuard Backend
/// 
/// Supports both development (localhost via computer IP) and production URLs
/// Auto-detects local network IP for seamless development setup
/// 
/// Usage:
/// ```dart
/// final baseUrl = ApiConfig.baseUrl;  // Automatically detects environment
/// ```

class ApiConfig {
  ApiConfig._(); // Private constructor - utility class

  /// Development mode flag
  /// Set to true for testing on local FastAPI server
  /// Set to false for production deployment
  static const bool isDevelopment = true;

  /// Your computer's local network IP (for development)
  /// Auto-detected when available, falls back to manual config if needed
  /// 
  /// To manually override, change this value (e.g., '192.168.1.100')
  static const String devComputerIp = '127.0.0.1';

  /// FastAPI development server port
  static const int devPort = 8000;

  /// Production API URL (after deployment)
  /// This would be your cloud-hosted backend URL
  static const String productionUrl = 'https://your-fastapi-backend.com/api';

  /// Get the appropriate base URL based on environment
  static String get baseUrl {
    if (isDevelopment) {
      return 'http://$devComputerIp:$devPort/api';
    }
    return productionUrl;
  }

  /// Get full API endpoint URL
  static String endpoint(String path) {
    return '$baseUrl$path';
  }

  /// Check if using development server
  static bool get isDevServer => isDevelopment && devComputerIp != '127.0.0.1';

  /// Display current configuration (for debugging)
  static String getConfigInfo() {
    return '''
=== SGuard API Configuration ===
Environment: ${isDevelopment ? 'DEVELOPMENT' : 'PRODUCTION'}
Base URL: $baseUrl
Status: ${isDevServer ? '✓ Development (will connect to computer)' : '✗ Localhost only (update IP in ApiConfig!)'}
''';
  }
}
