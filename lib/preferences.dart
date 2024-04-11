import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _lastOpenedKey = 'lastOpened';
  static const String _localeKey = 'locale';

  static final AppPreferences _singleton = AppPreferences._internal();

  factory AppPreferences() {
    return _singleton;
  }

  AppPreferences._internal();

  Future<void> setLastOpened(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenedKey, date.toIso8601String());
  }

  Future<DateTime?> getLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString(_lastOpenedKey);
    return storedDate == null ? null : DateTime.parse(storedDate);
  }

  Future<void> setLocale(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, language);
  }

  Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? "en";
  }
}
