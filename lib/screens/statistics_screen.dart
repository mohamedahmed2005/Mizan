import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';
import '../theme/theme_toggle_button.dart';
import '../services/storage_service.dart';
import '../services/app_state.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic> _weeklyData = {};
  List<String> _last7Days = [];
  int _totalPoints = 0;
  int _streak = 0;
  List<String> _achievements = [];

  @override
  void initState() {
    super.initState();
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
    _weeklyData = StorageService.getWeeklyStats();
    _totalPoints = StorageService.getPoints();
    _streak = StorageService.getPrayerStreak();
    _achievements = StorageService.getAchievements();

    final now = DateTime.now();
    _last7Days = List.generate(
      7,
      (i) => DateFormat('yyyy-MM-dd')
          .format(now.subtract(Duration(days: 6 - i))),
    );
    setState(() {});
  }

  int _prayersForDay(String date) {
    if (!_weeklyData.containsKey(date)) return 0;
    return (_weeklyData[date]['prayers'] ?? 0) as int;
  }

  double _studyForDay(String date) {
    if (!_weeklyData.containsKey(date)) return 0.0;
    return (_weeklyData[date]['study'] ?? 0.0).toDouble();
  }

  String _dayLabel(String date) {
    final dt = DateTime.parse(date);
    return DateFormat('EEE').format(dt);
  }

  String get _bestDay {
    if (_last7Days.isEmpty) return 'N/A';
    String best = _last7Days.first;
    double bestScore = 0;
    for (final d in _last7Days) {
      final score = _prayersForDay(d) * 10 + _studyForDay(d) * 5;
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    if (bestScore == 0) return 'N/A';
    return DateFormat('EEEE').format(DateTime.parse(best));
  }

  int get _totalPrayersWeek =>
      _last7Days.fold(0, (sum, d) => sum + _prayersForDay(d));

  double get _totalStudyWeek =>
      _last7Days.fold(0.0, (sum, d) => sum + _studyForDay(d));

  @override
  Widget build(BuildContext context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Statistics',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: R.sp(context, 28),
                          fontWeight: FontWeight.bold)),
                  const ThemeToggleButton(),
                ],
              ),
              const SizedBox(height: 4),
              Text('Your weekly overview',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: R.sp(context, 14))),
              const SizedBox(height: 24),

              // Summary Cards
              Row(
                children: [
                  _statCard('🕌', '$_totalPrayersWeek', 'Prayers\nThis Week',
                      AppColors.teal),
                  const SizedBox(width: 12),
                  _statCard(
                      '⏱',
                      '${_totalStudyWeek.toStringAsFixed(1)}h',
                      'Study\nThis Week',
                      AppColors.purple),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statCard(
                      '🔥', '$_streak', 'Prayer\nStreak', AppColors.orange),
                  const SizedBox(width: 12),
                  _statCard(
                      '⭐', '$_totalPoints', 'Total\nPoints', AppColors.gold),
                ],
              ),

              const SizedBox(height: 24),

              // Best day card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.teal.withValues(alpha: 0.2),
                      AppColors.purple.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text('🏆', style: TextStyle(fontSize: R.sp(context, 36))),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Best Productivity Day',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: R.sp(context, 13))),
                        Text(_bestDay,
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: R.sp(context, 22),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Prayer Chart
              _buildChartSection(
                title: '🕌 Prayers This Week',
                subtitle: 'Daily prayer completion (max 5)',
                child: _buildBarChart(
                  values: _last7Days
                      .map((d) => _prayersForDay(d).toDouble())
                      .toList(),
                  maxY: 5,
                  color: AppColors.teal,
                  labels: _last7Days.map(_dayLabel).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Study Chart
              _buildChartSection(
                title: '📚 Study Hours This Week',
                subtitle: 'Daily hours studied',
                child: _buildBarChart(
                  values: _last7Days.map((d) => _studyForDay(d)).toList(),
                  maxY: 10,
                  color: AppColors.purple,
                  labels: _last7Days.map(_dayLabel).toList(),
                ),
              ),

              const SizedBox(height: 24),

              _buildAchievementsSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: R.sp(context, 28))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontSize: R.sp(context, 20),
                          fontWeight: FontWeight.bold)),
                  Text(label,
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: R.sp(context, 11))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: R.sp(context, 16),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: R.sp(context, 12))),
          const SizedBox(height: 16),
          SizedBox(height: R.hp(context, 0.21), child: child),
        ],
      ),
    );
  }

  Widget _buildBarChart({
    required List<double> values,
    required double maxY,
    required Color color,
    required List<String> labels,
  }) {
    final barWidth = (R.wp(context, 1.0) - R.pd(context) * 2 - 36) /
        (labels.length * 1.8);

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final i = val.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Text(labels[i],
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: R.sp(context, 10)));
              },
            ),
          ),
        ),
        barGroups: List.generate(
          values.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                color: values[i] > 0 ? color : AppColors.border,
                width: barWidth.clamp(14.0, 28.0),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: AppColors.border.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildAchievementsSection() {
    final allAchievements = [
      {
        'id': 'all_prayers',
        'emoji': '🕌',
        'title': 'Prayer Champion',
        'desc': 'Complete all 5 prayers in a day',
      },
      {
        'id': 'all_habits',
        'emoji': '🌱',
        'title': 'Habit Master',
        'desc': 'Complete all habits in a day',
      },
      {
        'id': 'study_goal_AI',
        'emoji': '🤖',
        'title': 'AI Scholar',
        'desc': 'Reach your AI study goal',
      },
      {
        'id': 'study_goal_Database',
        'emoji': '🗄️',
        'title': 'DB Expert',
        'desc': 'Reach your Database study goal',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Achievements',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: R.sp(context, 18),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...allAchievements.map((a) {
          final unlocked = _achievements.contains(a['id']);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.gold.withValues(alpha: 0.08)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: unlocked
                      ? AppColors.gold.withValues(alpha: 0.4)
                      : AppColors.border),
            ),
            child: Row(
              children: [
                Text(
                  unlocked ? a['emoji']! : '🔒',
                  style: TextStyle(fontSize: R.sp(context, 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['title']!,
                          style: TextStyle(
                              color: unlocked
                                  ? AppColors.gold
                                  : AppColors.textSecondary,
                              fontSize: R.sp(context, 14),
                              fontWeight: FontWeight.w600)),
                      Text(a['desc']!,
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: R.sp(context, 12))),
                    ],
                  ),
                ),
                if (unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Unlocked',
                        style: TextStyle(
                            color: AppColors.gold,
                            fontSize: R.sp(context, 10),
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
