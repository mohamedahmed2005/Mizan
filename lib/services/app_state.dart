import 'package:flutter/material.dart';

/// Global app state notifier.
/// Call [notify] from any screen after modifying data to instantly
/// refresh all listeners (e.g. the Dashboard counters).
class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();
  AppState._();

  /// Call this after any data mutation (prayers, habits, study hours, tasks).
  void notify() => notifyListeners();
}
