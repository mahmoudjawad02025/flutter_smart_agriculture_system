class AppRuntimeConfig {
  const AppRuntimeConfig._();

  // Change this to 3 (or any value) when you want a different reminder window.
  static const int diseaseReuploadDelayDays = 2;

  // A result is considered healthy only when all detected labels match these keywords.
  // Add more keywords here to expand what counts as "healthy"
  // Example: ['healthy', 'green', 'normal', 'good']
  static const List<String> healthyKeywords = <String>['healthy'];

  // Disease labels to consider as confirmed diseases (optional whitelist)
  // If empty list, any non-healthy label is treated as disease
  // Example: ['powdery_mildew', 'downy_mildew', 'leaf_spot']
  static const List<String> confirmedDiseaseLabels = <String>[];

  // Enable debug logging in console
  static const bool enableDebugLogging = true;
}
