/// Application configuration constants
/// Centralized location for app branding and UI text
class AppConfig {
  // App name displayed in UI
  static const String appName = 'Custos';
  
  // App name with space (for display purposes)
  static const String appNameDisplay = 'Custos';
  
  // Copyright text
  static String get copyrightText => '$appName © ${DateTime.now().year}';
}
