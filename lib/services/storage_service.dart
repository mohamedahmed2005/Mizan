import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) throw Exception('StorageService not initialized');
    return _prefs!;
  }

  // ─── Prayer ───────────────────────────────────────────────
  static String _prayerKey(String date) => 'prayers_$date';

  static List<bool> getPrayers(String date) {
    final raw = prefs.getString(_prayerKey(date));
    if (raw == null) return List.filled(5, false);
    return List<bool>.from(jsonDecode(raw));
  }

  static Future<void> savePrayers(String date, List<bool> prayers) async {
    await prefs.setString(_prayerKey(date), jsonEncode(prayers));
  }

  static int getPrayerStreak() => prefs.getInt('prayer_streak') ?? 0;

  static Future<void> savePrayerStreak(int streak) async {
    await prefs.setInt('prayer_streak', streak);
  }

  // ─── Study ────────────────────────────────────────────────
  static List<Map<String, dynamic>> getSubjects() {
    final raw = prefs.getString('subjects');
    if (raw == null) {
      return [
        {'name': 'AI', 'studied': 0.0, 'target': 5.0},
        {'name': 'Database', 'studied': 0.0, 'target': 4.0},
        {'name': 'Operating System', 'studied': 0.0, 'target': 4.0},
        {'name': 'Flutter', 'studied': 0.0, 'target': 3.0},
      ];
    }
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> saveSubjects(List<Map<String, dynamic>> subjects) async {
    await prefs.setString('subjects', jsonEncode(subjects));
  }

  // ─── Habits ───────────────────────────────────────────────
  static String _habitKey(String date) => 'habits_$date';

  static List<Map<String, dynamic>> getHabitDefinitions() {
    final raw = prefs.getString('habit_defs');
    if (raw == null) {
      return [
        {'name': 'Drink Water', 'icon': '💧'},
        {'name': 'Exercise', 'icon': '🏋️'},
        {'name': 'Study', 'icon': '📚'},
        {'name': 'Read', 'icon': '📖'},
      ];
    }
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> saveHabitDefinitions(
      List<Map<String, dynamic>> habits) async {
    await prefs.setString('habit_defs', jsonEncode(habits));
  }

  static List<bool> getHabitChecks(String date, int count) {
    final raw = prefs.getString(_habitKey(date));
    if (raw == null) return List.filled(count, false);
    final list = List<bool>.from(jsonDecode(raw));
    while (list.length < count) {
      list.add(false);
    }
    return list;
  }

  static Future<void> saveHabitChecks(String date, List<bool> checks) async {
    await prefs.setString(_habitKey(date), jsonEncode(checks));
  }

  // ─── Daily Tasks ──────────────────────────────────────────
  static List<Map<String, dynamic>> getTasks(String date) {
    final raw = prefs.getString('tasks_$date');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> saveTasks(
      String date, List<Map<String, dynamic>> tasks) async {
    await prefs.setString('tasks_$date', jsonEncode(tasks));
  }

  // ─── Gamification ─────────────────────────────────────────
  static int getPoints() => prefs.getInt('points') ?? 0;

  static Future<void> addPoints(int pts) async {
    final current = getPoints();
    await prefs.setInt('points', current + pts);
  }

  static List<String> getAchievements() {
    return prefs.getStringList('achievements') ?? [];
  }

  static Future<void> unlockAchievement(String id) async {
    final list = getAchievements();
    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList('achievements', list);
    }
  }

  // ─── Weekly Stats ─────────────────────────────────────────
  static Map<String, dynamic> getWeeklyStats() {
    final raw = prefs.getString('weekly_stats');
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> saveWeeklyStats(Map<String, dynamic> stats) async {
    await prefs.setString('weekly_stats', jsonEncode(stats));
  }

  static Future<void> recordDayStats(
      String date, int prayers, double studyHours) async {
    final stats = getWeeklyStats();
    stats[date] = {'prayers': prayers, 'study': studyHours};
    await saveWeeklyStats(stats);
  }
}
