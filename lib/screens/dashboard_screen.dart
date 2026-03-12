import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';
import '../services/storage_service.dart';
import '../services/app_state.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _today;
  List<bool> _prayers = List.filled(5, false);
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _habitDefs = [];
  List<bool> _habitChecks = [];
  int _points = 0;
  int _streak = 0;
  List<String> _achievements = [];

  static const List<Map<String, String>> _motivations = [
    {
      'ayah': 'وَقُلِ اعْمَلُوا فَسَيَرَى اللَّهُ عَمَلَكُمْ',
      'ayah_ref': 'سورة التوبة: 105',
      'hadith': 'إن الله يحب إذا عمل أحدكم عملاً أن يتقنه',
      'hadith_ref': 'رواه البيهقي',
      'quote': 'Work hard in silence, let your success make the noise.',
    },
    {
      'ayah': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
      'ayah_ref': 'سورة الشرح: 5',
      'hadith': 'احرص على ما ينفعك واستعن بالله ولا تعجز',
      'hadith_ref': 'رواه مسلم',
      'quote': 'The secret of getting ahead is getting started.',
    },
    {
      'ayah': 'وَعَلَى اللَّهِ فَتَوَكَّلُوا إِن كُنتُم مُّؤْمِنِينَ',
      'ayah_ref': 'سورة المائدة: 23',
      'hadith': 'من سلك طريقاً يلتمس فيه علماً سهّل الله له طريقاً إلى الجنة',
      'hadith_ref': 'رواه مسلم',
      'quote': "Believe you can and you're halfway there.",
    },
    {
      'ayah': 'وَلَا تَيْأَسُوا مِن رَّوْحِ اللَّهِ',
      'ayah_ref': 'سورة يوسف: 87',
      'hadith': 'ما أصاب المسلم من نصب ولا وصب ولا هم ولا حزن إلا كفّر الله به',
      'hadith_ref': 'رواه البخاري',
      'quote': 'Push yourself, because no one else is going to do it for you.',
    },
  ];

  Map<String, String> get _todayMotivation {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _motivations[dayOfYear % _motivations.length];
  }

  @override
  void initState() {
    super.initState();
    _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadData();
    // Listen to global state changes for real-time updates
    AppState.instance.addListener(_loadData);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_loadData);
    super.dispose();
  }

  void _loadData() {
    if (!mounted) return;
    setState(() {
      _prayers = StorageService.getPrayers(_today);
      _subjects = StorageService.getSubjects();
      _habitDefs = StorageService.getHabitDefinitions();
      _habitChecks = StorageService.getHabitChecks(_today, _habitDefs.length);
      _points = StorageService.getPoints();
      _streak = StorageService.getPrayerStreak();
      _achievements = StorageService.getAchievements();
    });
  }

  int get _prayersDone => _prayers.where((p) => p).length;
  double get _prayerProgress => _prayersDone / 5.0;

  double get _studyProgress {
    if (_subjects.isEmpty) return 0;
    double total = 0, target = 0;
    for (final s in _subjects) {
      total += (s['studied'] ?? 0.0).toDouble();
      target += (s['target'] ?? 5.0).toDouble();
    }
    return target == 0 ? 0 : (total / target).clamp(0.0, 1.0);
  }

  int get _habitsDone => _habitChecks.where((h) => h).length;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final motivation = _todayMotivation;
    final pad = R.pd(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppColors.teal,
          backgroundColor: AppColors.card,
          child: ListView(
            padding: EdgeInsets.all(pad),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting,
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: R.sp(context, 14))),
                      const SizedBox(height: 4),
                      Text('Dashboard',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: R.sp(context, 28),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Text('⭐', style: TextStyle(fontSize: R.sp(context, 16))),
                        const SizedBox(width: 6),
                        Text('$_points pts',
                            style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: R.sp(context, 14))),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: R.sp(context, 12))),

              const SizedBox(height: 24),

              // Progress Circles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _progressCircle(
                    percent: _prayerProgress,
                    color: AppColors.teal,
                    emoji: '🕌',
                    title: 'Prayers',
                    subtitle: '$_prayersDone/5',
                  ),
                  _progressCircle(
                    percent: _studyProgress,
                    color: AppColors.purple,
                    emoji: '📚',
                    title: 'Study',
                    subtitle:
                        '${(_studyProgress * 100).toStringAsFixed(0)}%',
                  ),
                  _progressCircle(
                    percent: _habitDefs.isEmpty
                        ? 0
                        : _habitsDone / _habitDefs.length,
                    color: AppColors.green,
                    emoji: '🌱',
                    title: 'Habits',
                    subtitle: '$_habitsDone/${_habitDefs.length}',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Streak + Achievements
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.orange.withValues(alpha: 0.2),
                            AppColors.gold.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Text('🔥', style: TextStyle(fontSize: R.sp(context, 28))),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$_streak',
                                  style: TextStyle(
                                      color: AppColors.gold,
                                      fontSize: R.sp(context, 24),
                                      fontWeight: FontWeight.bold)),
                              Text('Day Streak',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: R.sp(context, 11))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.purple.withValues(alpha: 0.2),
                            AppColors.purpleLight.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Text('🏆', style: TextStyle(fontSize: R.sp(context, 28))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_achievements.length}',
                                    style: TextStyle(
                                        color: AppColors.purpleLight,
                                        fontSize: R.sp(context, 24),
                                        fontWeight: FontWeight.bold)),
                                Text('Achievements',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: R.sp(context, 11))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Motivation Card
              Container(
                padding: EdgeInsets.all(pad),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('✨ Daily Motivation',
                              style: TextStyle(
                                  color: AppColors.teal,
                                  fontSize: R.sp(context, 11),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Ayah
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Directionality(
                            textDirection: Directionality.of(context),
                            child: Text(
                              '﴿${motivation['ayah']!}﴾',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: R.sp(context, 16),
                                  height: 1.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(motivation['ayah_ref']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.teal,
                                  fontSize: R.sp(context, 11))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Hadith
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Directionality(
                            textDirection: Directionality.of(context),
                            child: Text(
                              '"${motivation['hadith']!}"',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: R.sp(context, 13),
                                  height: 1.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(motivation['hadith_ref']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: R.sp(context, 11))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quote
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Text('💬', style: TextStyle(fontSize: R.sp(context, 18))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('"${motivation['quote']!}"',
                                style: TextStyle(
                                    color: AppColors.purpleLight,
                                    fontSize: R.sp(context, 13),
                                    fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressCircle({
    required double percent,
    required Color color,
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    final radius = R.wp(context, 0.13);
    return Column(
      children: [
        CircularPercentIndicator(
          radius: radius,
          lineWidth: radius * 0.155,
          percent: percent,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: TextStyle(fontSize: R.sp(context, 20))),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color: color,
                      fontSize: R.sp(context, 11),
                      fontWeight: FontWeight.bold)),
            ],
          ),
          progressColor: color,
          backgroundColor: AppColors.border,
          animation: true,
          animationDuration: 1000,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 8),
        Text(title,
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: R.sp(context, 12))),
      ],
    );
  }
}
