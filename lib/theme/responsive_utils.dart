import 'package:flutter/material.dart';

/// Responsive utilities — all values scale relative to a 390px base width.
class R {
  /// Scaled font size. Pass [base] as the design size at 390px width.
  static double sp(BuildContext context, double base) {
    final width = MediaQuery.of(context).size.width;
    return (base * width / 390).clamp(base * 0.75, base * 1.25);
  }

  /// Fraction of screen width. e.g. wp(context, 0.1) → 10% of width.
  static double wp(BuildContext context, double fraction) {
    return MediaQuery.of(context).size.width * fraction;
  }

  /// Fraction of screen height.
  static double hp(BuildContext context, double fraction) {
    return MediaQuery.of(context).size.height * fraction;
  }

  /// Horizontal page padding — 5% of width, clamped between 14 and 24.
  static double pd(BuildContext context) {
    return (MediaQuery.of(context).size.width * 0.05).clamp(14.0, 24.0);
  }
}
