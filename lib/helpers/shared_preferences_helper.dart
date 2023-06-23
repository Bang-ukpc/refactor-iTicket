import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static Future<void> setStringValue(String key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value!);
  }

  static Future<String?> getStringValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(key);
    return value;
  }

  static Future<void> removeStringValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> setBoolValue(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool?> getBoolValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final bool? value = prefs.getBool(key);
    return value;
  }
}
