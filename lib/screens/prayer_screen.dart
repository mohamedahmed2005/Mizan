import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';
import '../services/storage_service.dart';
import '../services/app_state.dart';
import '../models/prayer_model.dart';
import 'package:intl/intl.dart';
import '../services/prayer_api_service.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen>
    with TickerProviderStateMixin {
  late List<bool> _prayers;
  late String _today;
  late int _streak;
  late List<AnimationController> _checkControllers;
  late List<Animation<double>> _checkAnimations;

  @override
  void initState() {
    super.initState();
    _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _prayers = StorageService.getPrayers(_today);
    _streak = StorageService.getPrayerStreak();

    _checkControllers = List.generate(
      5,
      (i) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 300)),
    );
    _checkAnimations = _checkControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.elasticOut))
        .toList();

    for (int i = 0; i < 5; i++) {
      if (_prayers[i]) {
        _checkControllers[i].value = 1.0;
      }
    }
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    final times = await PrayerApiService.fetchPrayerTimes();
    if (times != null && times.length == 5 && mounted) {
      setState(() {
        PrayerNames.times = times;
      });
    }
  }

  @override
  void dispose() {
    for (var c in _checkControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _togglePrayer(int index) async {
    // If already marked as done, show a warning and do nothing
    if (_prayers[index]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                '${PrayerNames.names[index]} already prayed! ✅',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if it's too early for this prayer
    final now = DateTime.now();
    final timeString = PrayerNames.times[index];
    
    try {
      final parsedTime = DateFormat('h:mm a').parse(timeString);
      // Create a DateTime object for today with the parsed hours and minutes
      final prayerTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);

      if (now.isBefore(prayerTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'It\'s too early for ${PrayerNames.names[index]}! (Starts at $timeString) ⏳',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('Error parsing prayer time: $e');
      // If parsing fails for any reason, we just let them check it off
    }

    // Mark as done
    setState(() {
      _prayers[index] = true;
    });
    _checkControllers[index].forward(from: 0);
    await StorageService.savePrayers(_today, _prayers);

    final doneCnt = _prayers.where((p) => p).length;
    if (doneCnt == 5) {
      final newStreak = _streak + 1;
      setState(() => _streak = newStreak);
      await StorageService.savePrayerStreak(newStreak);
      await StorageService.addPoints(50);
      await StorageService.unlockAchievement('all_prayers');
    }
    await StorageService.recordDayStats(_today, doneCnt, _getTotalStudyHours());

    // Notify other screens (Dashboard, Stats) to update in real-time
    AppState.instance.notify();
  }

  double _getTotalStudyHours() {
    final subjects = StorageService.getSubjects();
    return subjects.fold(0.0, (sum, s) => sum + (s['studied'] ?? 0.0));
  }

  int get _doneCount => _prayers.where((p) => p).length;
  double get _progress => _doneCount / 5.0;

  @override
  Widget build(BuildContext context) {
    final pad = R.pd(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning 🌙'
        : hour < 17
            ? 'Good Afternoon ☀️'
            : 'Good Evening 🌙';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: R.sp(context, 14))),
              const SizedBox(height: 4),
              Text('Prayer Tracker',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: R.sp(context, 28),
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircularPercentIndicator(
                    radius: 80,
                    lineWidth: 10,
                    percent: _progress,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_doneCount/5',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'prayers',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    progressColor: AppColors.teal,
                    backgroundColor: AppColors.border,
                    animation: true,
                    animationDuration: 800,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(width: 12),
                  Flexible(child: _buildStreakCard()),
                ],
              ),

              const SizedBox(height: 32),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
                ),
                child: Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: TextStyle(
                      color: AppColors.teal,
                      fontSize: R.sp(context, 13),
                      fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 20),

              ...List.generate(5, (i) => _buildPrayerCard(i)),

              const SizedBox(height: 20),

              if (_doneCount == 5) _buildCompletionBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: EdgeInsets.all(R.wp(context, 0.05)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.3),
            AppColors.gold.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔥', style: TextStyle(fontSize: R.sp(context, 36))),
          const SizedBox(height: 8),
          Text('$_streak',
              style: TextStyle(
                  color: AppColors.gold,
                  fontSize: R.sp(context, 32),
                  fontWeight: FontWeight.bold)),
          Text('Day Streak',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: R.sp(context, 12))),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(int index) {
    final done = _prayers[index];
    return GestureDetector(
      onTap: () => _togglePrayer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: done ? AppColors.teal.withValues(alpha: 0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done
                ? AppColors.teal.withValues(alpha: 0.6)
                : AppColors.border,
            width: done ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ScaleTransition(
              scale: _checkAnimations[index],
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.teal : Colors.transparent,
                  border: Border.all(
                    color: done ? AppColors.teal : AppColors.textMuted,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(PrayerNames.names[index],
                      style: TextStyle(
                          color: done ? AppColors.teal : AppColors.textPrimary,
                          fontSize: R.sp(context, 16),
                          fontWeight: FontWeight.w600)),
                  Text(PrayerNames.arabicNames[index],
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: R.sp(context, 12))),
                ],
              ),
            ),
            Text(PrayerNames.times[index],
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: R.sp(context, 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: R.sp(context, 32))),
          const SizedBox(height: 8),
          Text('All Prayers Complete!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: R.sp(context, 18),
                  fontWeight: FontWeight.bold)),
          Text('+50 Points Earned',
              style: TextStyle(
                  color: Colors.white70, fontSize: R.sp(context, 13))),
        ],
      ),
    );
  }
}
