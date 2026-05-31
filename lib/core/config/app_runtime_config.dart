import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRuntimeConfig {
  const AppRuntimeConfig._();

  static const String _diseaseReuploadDelayDaysKey =
      'disease_reupload_delay_days';
  static const String _healthyKeywordsKey = 'healthy_keywords';
  static const String _confirmedDiseaseLabelsKey = 'confirmed_disease_labels';
  static const String _autoAnalyzeKey = 'auto_analyze';
  static const String _showAdvancedDetailsKey = 'show_advanced_details';
  static const String _pushNotificationsKey = 'push_notifications';
  static const String _strongAlertModeKey = 'strong_alert_mode';
  static const String _showDeveloperToolsKey = 'show_developer_tools';

  static final ValueNotifier<int> diseaseReuploadDelayDays = ValueNotifier<int>(
    2,
  );

  static final ValueNotifier<List<String>> healthyKeywords =
      ValueNotifier<List<String>>(<String>['Healthy']);

  static final ValueNotifier<List<String>> confirmedDiseaseLabels =
      ValueNotifier<List<String>>(<String>[]);

  static final ValueNotifier<bool> autoAnalyze = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> showAdvancedDetails = ValueNotifier<bool>(
    true,
  );
  static final ValueNotifier<bool> pushNotifications = ValueNotifier<bool>(
    true,
  );
  static final ValueNotifier<bool> strongAlertMode = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> showDeveloperTools = ValueNotifier<bool>(
    false,
  );

  static const bool enableDebugLogging = true;

  static Future<void> initialize() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    diseaseReuploadDelayDays.value =
        preferences.getInt(_diseaseReuploadDelayDaysKey) ?? 2;
    healthyKeywords.value =
        preferences.getStringList(_healthyKeywordsKey) ?? <String>['Healthy'];
    confirmedDiseaseLabels.value =
        preferences.getStringList(_confirmedDiseaseLabelsKey) ?? <String>[];

    autoAnalyze.value = preferences.getBool(_autoAnalyzeKey) ?? true;
    showAdvancedDetails.value =
        preferences.getBool(_showAdvancedDetailsKey) ?? true;
    pushNotifications.value =
        preferences.getBool(_pushNotificationsKey) ?? true;
    strongAlertMode.value = preferences.getBool(_strongAlertModeKey) ?? false;
    showDeveloperTools.value =
        preferences.getBool(_showDeveloperToolsKey) ?? false;
  }

  static Future<void> setAutoAnalyze(bool value) async {
    autoAnalyze.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_autoAnalyzeKey, value);
  }

  static Future<void> setShowAdvancedDetails(bool value) async {
    showAdvancedDetails.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_showAdvancedDetailsKey, value);
  }

  static Future<void> setPushNotifications(bool value) async {
    pushNotifications.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_pushNotificationsKey, value);
  }

  static Future<void> setStrongAlertMode(bool value) async {
    strongAlertMode.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_strongAlertModeKey, value);
  }

  static Future<void> setShowDeveloperTools(bool value) async {
    showDeveloperTools.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_showDeveloperToolsKey, value);
  }

  static Future<void> setDiseaseReuploadDelayDays(int value) async {
    diseaseReuploadDelayDays.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_diseaseReuploadDelayDaysKey, value);
  }

  static Future<void> setHealthyKeywords(List<String> values) async {
    healthyKeywords.value = List<String>.unmodifiable(values);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_healthyKeywordsKey, values);
  }

  static Future<void> setConfirmedDiseaseLabels(List<String> values) async {
    confirmedDiseaseLabels.value = List<String>.unmodifiable(values);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_confirmedDiseaseLabelsKey, values);
  }
}
