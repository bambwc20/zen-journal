import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

@riverpod
class AppSettings extends _$AppSettings {
  late SharedPreferences _prefs;

  @override
  Future<Map<String, dynamic>> build() async {
    _prefs = await SharedPreferences.getInstance();
    return {
      'notifications_enabled': _prefs.getBool('notifications_enabled') ?? true,
      'language': _prefs.getString('language') ?? 'ko',
    };
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
    ref.invalidateSelf();
  }

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
    ref.invalidateSelf();
  }
}
