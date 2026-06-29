import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRuntimeConfig {
  AppRuntimeConfig._();

  static const String _diseaseReuploadDelayDaysKey =
      'disease_reupload_delay_days';
  static const String _healthyKeywordsKey = 'healthy_keywords';
  static const String _confirmedDiseaseLabelsKey = 'confirmed_disease_labels';
  static const String _autoAnalyzeKey = 'auto_analyze';
  static const String _showAdvancedDetailsKey = 'show_advanced_details';
  static const String _pushNotificationsKey = 'push_notifications';
  static const String _strongAlertModeKey = 'strong_alert_mode';
  static const String _showDeveloperToolsKey = 'show_developer_tools';
  static const String _showConfigAdvancedSectionsKey =
      'show_config_advanced_sections';
  static const String _showConfigRefreshTimeKey = 'show_config_refresh_time';
  static const String _showConfigAutoWaterKey = 'show_config_auto_water';
  static const String _showConfigAutoFertKey = 'show_config_auto_fert';
  static const String _showConfigTanksKey = 'show_config_tanks';
  static const String _showConfigFert2DoseKey = 'show_config_fert2_dose';
  static const String _showConfigDetectionRulesKey =
      'show_config_detection_rules';

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

  static final ValueNotifier<bool> showConfigRefreshTime = ValueNotifier<bool>(
    true,
  );
  static final ValueNotifier<bool> showConfigAutoWater = ValueNotifier<bool>(
    true,
  );
  static final ValueNotifier<bool> showConfigAutoFert = ValueNotifier<bool>(
    true,
  );
  static final ValueNotifier<bool> showConfigTanks = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> showConfigFert2Dose = ValueNotifier<bool>(
    true,
  );
  static final ValueNotifier<bool> showConfigDetectionRules =
      ValueNotifier<bool>(true);

  static Listenable get configSectionVisibilityListenables => Listenable.merge(
    <Listenable>[
      showConfigRefreshTime,
      showConfigAutoWater,
      showConfigAutoFert,
      showConfigTanks,
      showConfigFert2Dose,
      showConfigDetectionRules,
    ],
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

    _loadConfigSectionVisibility(preferences);
  }

  static void _loadConfigSectionVisibility(SharedPreferences preferences) {
    final bool hasLegacy = preferences.containsKey(_showConfigAdvancedSectionsKey);
    final bool hasPerSection = preferences.containsKey(_showConfigRefreshTimeKey);

    if (hasLegacy && !hasPerSection) {
      final bool legacyVisible =
          preferences.getBool(_showConfigAdvancedSectionsKey) ?? true;
      showConfigRefreshTime.value = legacyVisible;
      showConfigAutoWater.value = legacyVisible;
      showConfigAutoFert.value = legacyVisible;
      showConfigTanks.value = legacyVisible;
      showConfigFert2Dose.value = legacyVisible;
      showConfigDetectionRules.value = legacyVisible;
      return;
    }

    showConfigRefreshTime.value =
        preferences.getBool(_showConfigRefreshTimeKey) ?? true;
    showConfigAutoWater.value =
        preferences.getBool(_showConfigAutoWaterKey) ?? true;
    showConfigAutoFert.value =
        preferences.getBool(_showConfigAutoFertKey) ?? true;
    showConfigTanks.value = preferences.getBool(_showConfigTanksKey) ?? true;
    showConfigFert2Dose.value =
        preferences.getBool(_showConfigFert2DoseKey) ?? true;
    showConfigDetectionRules.value =
        preferences.getBool(_showConfigDetectionRulesKey) ?? true;
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

  static Future<void> setShowConfigRefreshTime(bool value) async {
    showConfigRefreshTime.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_showConfigRefreshTimeKey, value);
  }

  static Future<void> setShowConfigAutoWater(bool value) async {
    showConfigAutoWater.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_showConfigAutoWaterKey, value);
  }

  static Future<void> setShowConfigAutoFert(bool value) async {
    showConfigAutoFert.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_showConfigAutoFertKey, value);
  }

  static Future<void> setShowConfigTanks(bool value) async {
    showConfigTanks.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_showConfigTanksKey, value);
  }

  static Future<void> setShowConfigFert2Dose(bool value) async {
    showConfigFert2Dose.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_showConfigFert2DoseKey, value);
  }

  static Future<void> setShowConfigDetectionRules(bool value) async {
    showConfigDetectionRules.value = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_showConfigDetectionRulesKey, value);
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
