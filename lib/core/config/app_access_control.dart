import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppAccessControl {
  AppAccessControl._();

  static final AppAccessControl instance = AppAccessControl._();

  static const String _skipLoginKey = 'skip_login_screen';

  final ValueNotifier<bool> skipLogin = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    skipLogin.value = preferences.getBool(_skipLoginKey) ?? false;
  }

  Future<void> setSkipLogin(bool value) async {
    skipLogin.value = value;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_skipLoginKey, value);
  }
}
