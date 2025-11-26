/// Environment configuration helper
class EnvironmentConfig {
  static const String dev = 'dev';
  static const String test = 'test';
  static const String prod = 'prod';

  static String get current => const String.fromEnvironment('ENV', defaultValue: dev);

  static bool get isDev => current == dev;
  static bool get isTest => current == test;
  static bool get isProd => current == prod;

  static String get displayName {
    switch (current) {
      case dev:
        return 'Development';
      case test:
        return 'Testing';
      case prod:
        return 'Production';
      default:
        return 'Unknown';
    }
  }
}