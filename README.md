# ⚖️ Mizan

> **Prayer · Study · Habits · Life** — Your all-in-one personal tracker built with Flutter.

---

## 📱 About

**Mizan** is a Flutter mobile application that helps you stay consistent with your daily prayers, study goals, habits, and overall life progress. It features:

- 🕌 **Prayer Tracker** — Log your 5 daily prayers. Once marked, a prayer cannot be un-done (one-way only).
- 📚 **Study Tracker** — Track subjects, study hours, and progress toward your targets.
- 🌱 **Habits Tracker** — Define and track daily habits with streaks.
- 📊 **Statistics** — Visualise your weekly/monthly performance with charts.
- 🏠 **Dashboard** — Overview of prayers, study, habits, points, and streak at a glance.
- ✨ **Animated Splash Screen** — Smooth animated intro on every launch.

---

## 🗂️ Project Structure

```
lib/
├── main.dart                    # App entry point & bottom navigation shell
├── models/
│   ├── prayer_model.dart        # Prayer names, times, Arabic names
│   ├── task_model.dart          # Task data model
│   └── habit_model.dart         # Habit data model
├── screens/
│   ├── splash_screen.dart       # Animated splash/loading screen
│   ├── dashboard_screen.dart    # Home dashboard with overview cards
│   ├── prayer_screen.dart       # Daily prayer tracker
│   ├── study_screen.dart        # Study hours tracker
│   ├── habits_screen.dart       # Habit tracker
│   └── statistics_screen.dart   # Charts & statistics
├── services/
│   ├── storage_service.dart     # SharedPreferences persistence layer
│   └── app_state.dart           # Global state notifier (real-time updates)
└── theme/
    ├── app_theme.dart           # Colors, dark theme
    └── responsive_utils.dart    # Responsive sizing helpers
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.11
- Dart ≥ 3.11
- Android Studio / VS Code with Flutter extension

### Run the App

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on connected device or emulator
flutter run

# 3. (Optional) Generate app icons from assets/icon.png
dart run flutter_launcher_icons
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `shared_preferences` | Local data persistence |
| `percent_indicator` | Circular & linear progress indicators |
| `google_fonts` | Poppins typography |
| `fl_chart` | Bar/line charts in Statistics |
| `intl` | Date formatting |
| `flutter_launcher_icons` | App icon generation |

---

## 🎨 Design

- **Dark theme** with a teal accent (`#00BFA5`)
- **Responsive layout** — scales across screen sizes
- **Animated UI** — micro-animations on interactions
- **One-way prayer marking** — prevents accidental resets

---

## 📄 License

This project is for academic use only.
