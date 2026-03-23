import 'package:flutter/material.dart';
import 'storage_service.dart';

/// Global app state notifier.
/// Call [notify] from any screen after modifying data to instantly
/// refresh all listeners (e.g. the Dashboard counters).
class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();
  AppState._();

  bool isDarkMode = true;

  /// Initialize state from storage
  void initFromStorage() {
    isDarkMode = StorageService.getIsDarkMode();
  }

  /// Call this to toggle the theme mode between Light and Dark
  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    await StorageService.saveIsDarkMode(isDarkMode);
    notifyListeners();
  }

  /// Call this after any data mutation (prayers, habits, study hours, tasks).
  void notify() => notifyListeners();
}
