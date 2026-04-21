import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRuntimeConfig {
  const AppRuntimeConfig._();

  static const String _diseaseReuploadDelayDaysKey =
      'disease_reupload_delay_days';
  static const String _healthyKeywordsKey = 'healthy_keywords';
  static const String _confirmedDiseaseLabelsKey = 'confirmed_disease_labels';
  static const String _moistMinKey = 'goal_moist_min';
  static const String _moistMaxKey = 'goal_moist_max';
  static const String _nMinKey = 'goal_n_min';
  static const String _nMaxKey = 'goal_n_max';
  static const String _pMinKey = 'goal_p_min';
  static const String _pMaxKey = 'goal_p_max';
  static const String _kMinKey = 'goal_k_min';
  static const String _kMaxKey = 'goal_k_max';
  static const String _leafGoalKey = 'goal_leaf_goal';

  static final ValueNotifier<int> diseaseReuploadDelayDays = ValueNotifier<int>(
    2,
  );

  static final ValueNotifier<List<String>> healthyKeywords =
      ValueNotifier<List<String>>(<String>['Healthy']);

  static final ValueNotifier<List<String>> confirmedDiseaseLabels =
      ValueNotifier<List<String>>(<String>[]);

  static final ValueNotifier<int> moistMin = ValueNotifier<int>(30);
  static final ValueNotifier<int> moistMax = ValueNotifier<int>(65);
  static final ValueNotifier<int> nMin = ValueNotifier<int>(100);
  static final ValueNotifier<int> nMax = ValueNotifier<int>(180);
  static final ValueNotifier<int> pMin = ValueNotifier<int>(40);
  static final ValueNotifier<int> pMax = ValueNotifier<int>(80);
  static final ValueNotifier<int> kMin = ValueNotifier<int>(150);
  static final ValueNotifier<int> kMax = ValueNotifier<int>(250);
  static final ValueNotifier<String> leafGoal = ValueNotifier<String>(
    'Healthy',
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
    moistMin.value = preferences.getInt(_moistMinKey) ?? 30;
    moistMax.value = preferences.getInt(_moistMaxKey) ?? 65;
    nMin.value = preferences.getInt(_nMinKey) ?? 100;
    nMax.value = preferences.getInt(_nMaxKey) ?? 180;
    pMin.value = preferences.getInt(_pMinKey) ?? 40;
    pMax.value = preferences.getInt(_pMaxKey) ?? 80;
    kMin.value = preferences.getInt(_kMinKey) ?? 150;
    kMax.value = preferences.getInt(_kMaxKey) ?? 250;
    leafGoal.value = preferences.getString(_leafGoalKey) ?? 'Healthy';
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

  static Future<void> setCropTargets({
    required int moistMinValue,
    required int moistMaxValue,
    required int nMinValue,
    required int nMaxValue,
    required int pMinValue,
    required int pMaxValue,
    required int kMinValue,
    required int kMaxValue,
    required String leafGoalValue,
  }) async {
    moistMin.value = moistMinValue;
    moistMax.value = moistMaxValue;
    nMin.value = nMinValue;
    nMax.value = nMaxValue;
    pMin.value = pMinValue;
    pMax.value = pMaxValue;
    kMin.value = kMinValue;
    kMax.value = kMaxValue;
    leafGoal.value = leafGoalValue;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_moistMinKey, moistMinValue);
    await preferences.setInt(_moistMaxKey, moistMaxValue);
    await preferences.setInt(_nMinKey, nMinValue);
    await preferences.setInt(_nMaxKey, nMaxValue);
    await preferences.setInt(_pMinKey, pMinValue);
    await preferences.setInt(_pMaxKey, pMaxValue);
    await preferences.setInt(_kMinKey, kMinValue);
    await preferences.setInt(_kMaxKey, kMaxValue);
    await preferences.setString(_leafGoalKey, leafGoalValue);
  }
}
