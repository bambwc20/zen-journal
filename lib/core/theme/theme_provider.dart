import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

@riverpod
class AppThemeMode extends _$AppThemeMode {
  static const _key = 'theme_mode';

  @override
  material.ThemeMode build() => material.ThemeMode.system;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = material.ThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => material.ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(material.ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  void toggle() {
    final next = switch (state) {
      material.ThemeMode.light => material.ThemeMode.dark,
      material.ThemeMode.dark => material.ThemeMode.system,
      material.ThemeMode.system => material.ThemeMode.light,
    };
    setThemeMode(next);
  }
}
