import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../services/app_state.dart';

/// A compact circular button that toggles between Light and Dark mode.
/// Drop it anywhere in a screen's header.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: IconButton(
          icon: Icon(
            AppState.instance.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: AppColors.gold,
          ),
          onPressed: () => AppState.instance.toggleTheme(),
          tooltip: AppState.instance.isDarkMode ? 'Light Mode' : 'Dark Mode',
          iconSize: 22,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }
}
