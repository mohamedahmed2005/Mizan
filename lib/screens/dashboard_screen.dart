import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import '../theme/responsive_utils.dart';
import '../theme/theme_toggle_button.dart';
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
      'ayah': 'وَقُلِ اعْمَلُوا فَسَيَرَى اللَّهُ عَمَلَكُمْ وَرَسُولُهُ وَالْمُؤْمِنُونَ',
      'ayah_ref': 'سورة التوبة: 105',
      'hadith': 'إن الله يحب إذا عمل احدكم عملا ان يتقنه',
      'hadith_ref': 'رواه البيهقي',
      'quote': 'Work hard in silence, let your success make the noise.',
    },
    {
      'ayah': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا — إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      'ayah_ref': 'سورة الشرح: 5-6',
      'hadith': 'احرص على ما ينفعك واستعن بالله ولا تعجز',
      'hadith_ref': 'رواه مسلم',
      'quote': 'The secret of getting ahead is getting started.',
    },
    {
      'ayah': 'وَعَلَى اللَّهِ فَتَوَكَّلُوا إِن كُنتُم مُّؤْمِنِينَ',
      'ayah_ref': 'سورة المائدة: 23',
      'hadith': 'من سلك طريقا يلتمس فيه علما سهل الله له طريقا الى الجنة',
      'hadith_ref': 'رواه مسلم',
      'quote': "Believe you can and you're halfway there.",
    },
    {
      'ayah': 'وَلَا تَيْأَسُوا مِن رَّوْحِ اللَّهِ، إِنَّهُ لَا يَيْأَسُ مِن رَّوْحِ اللَّهِ إِلَّا الْقَوْمُ الْكَافِرُونَ',
      'ayah_ref': 'سورة يوسف: 87',
      'hadith': 'ما اصاب المسلم من نصب ولا وصب ولا هم ولا حزن الا كفر الله به',
      'hadith_ref': 'رواه البخاري',
      'quote': 'Push yourself, because no one else is going to do it for you.',
    },
    {
      'ayah': 'إِنَّ اللَّهَ لَا يُغَيِّرُ مَا بِقَوْمٍ حَتَّى يُغَيِّرُوا مَا بِأَنفُسِهِمْ',
      'ayah_ref': 'سورة الرعد: 11',
      'hadith': 'من جد وجد، ومن زرع حصد، ومن سلك الطريق وصل',
      'hadith_ref': 'حكمة عربية',
      'quote': 'Be the change you wish to see in the world.',
    },
    {
      'ayah': 'وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ، وَإِنَّهَا لَكَبِيرَةٌ إِلَّا عَلَى الْخَاشِعِينَ',
      'ayah_ref': 'سورة البقرة: 45',
      'hadith': 'عجبا لامر المؤمن، إن أمره كله خير، إن اصابته سراء شكر فكان خيرا، وإن اصابته ضراء صبر فكان خيرا',
      'hadith_ref': 'رواه مسلم',
      'quote': 'Patience is not the ability to wait, but how you act while waiting.',
    },
    {
      'ayah': 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ، إِنَّ اللَّهَ بَالِغُ أَمْرِهِ',
      'ayah_ref': 'سورة الطلاق: 3',
      'hadith': 'لو انكم توكلون على الله حق توكله لرزقكم كما يرزق الطير',
      'hadith_ref': 'رواه الترمذي',
      'quote': 'Trust the process and trust the journey.',
    },
    {
      'ayah': 'وَأَن لَّيْسَ لِلْإِنسَانِ إِلَّا مَا سَعَى',
      'ayah_ref': 'سورة النجم: 39',
      'hadith': 'ما ملأ ابن آدم وعاء شرا من بطن، بحسب ابن آدم أكلات يقمن صلبه',
      'hadith_ref': 'رواه الترمذي',
      'quote': 'Success is the sum of small efforts, repeated day in and day out.',
    },
    {
      'ayah': 'وَفِي ذَلِكَ فَلْيَتَنَافَسِ الْمُتَنَافِسُونَ',
      'ayah_ref': 'سورة المطففين: 26',
      'hadith': 'المؤمن القوي خير وأحب الى الله من المؤمن الضعيف، وفي كل خير',
      'hadith_ref': 'رواه مسلم',
      'quote': 'Strive not to be a success, but rather to be of value.',
    },
    {
      'ayah': 'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ',
      'ayah_ref': 'سورة البقرة: 153',
      'hadith': 'الصلاة نور، والصدقة برهان، والصبر ضياء',
      'hadith_ref': 'رواه مسلم',
      'quote': 'Discipline is the bridge between goals and accomplishment.',
    },
    {
      'ayah': 'وَلَنَبْلُوَنَّكُم بِشَيْءٍ مِّنَ الْخَوْفِ وَالْجُوعِ وَنَقْصٍ مِّنَ الْأَمْوَالِ وَالْأَنفُسِ وَالثَّمَرَاتِ، وَبَشِّرِ الصَّابِرِينَ',
      'ayah_ref': 'سورة البقرة: 155',
      'hadith': 'ما يزال البلاء بالمؤمن والمؤمنة في نفسه وولده وماله حتى يلقى الله وما عليه خطيئة',
      'hadith_ref': 'رواه الترمذي',
      'quote': 'Hard times may have held you down, but they will not last forever.',
    },
    {
      'ayah': 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
      'ayah_ref': 'سورة البقرة: 152',
      'hadith': 'من لم يشكر الناس لم يشكر الله',
      'hadith_ref': 'رواه الترمذي',
      'quote': 'Gratitude turns what we have into enough.',
    },
    {
      'ayah': 'وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ إِن كُنتُم مُّؤْمِنِينَ',
      'ayah_ref': 'سورة آل عمران: 139',
      'hadith': 'المؤمن لا يلدغ من جحر واحد مرتين',
      'hadith_ref': 'رواه البخاري',
      'quote': 'You were not made to surrender — you were made to rise.',
    },
    {
      'ayah': 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      'ayah_ref': 'سورة الشرح: 6',
      'hadith': 'يسروا ولا تعسروا، وبشروا ولا تنفروا',
      'hadith_ref': 'رواه البخاري',
      'quote': 'After every storm the sun will smile.',
    },
    {
      'ayah': 'رَبِّ اشْرَحْ لِي صَدْرِي، وَيَسِّرْ لِي أَمْرِي',
      'ayah_ref': 'سورة طه: 25-26',
      'hadith': 'اللهم لا سهل إلا ما جعلته سهلا، وأنت تجعل الحزن إن شئت سهلا',
      'hadith_ref': 'رواه ابن حبان',
      'quote': 'Start where you are. Use what you have. Do what you can.',
    },
    {
      'ayah': 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ، أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ',
      'ayah_ref': 'سورة البقرة: 186',
      'hadith': 'أقرب ما يكون العبد من ربه وهو ساجد فأكثروا الدعاء',
      'hadith_ref': 'رواه مسلم',
      'quote': 'You are never alone when you turn to Allah.',
    },
    {
      'ayah': 'وَلَا تُلْقُوا بِأَيْدِيكُمْ إِلَى التَّهْلُكَةِ، وَأَحْسِنُوا إِنَّ اللَّهَ يُحِبُّ الْمُحْسِنِينَ',
      'ayah_ref': 'سورة البقرة: 195',
      'hadith': 'إن الله كتب الإحسان على كل شيء',
      'hadith_ref': 'رواه مسلم',
      'quote': 'Excellence is not a destination but a continuous journey.',
    },
    {
      'ayah': 'وَشَاوِرْهُمْ فِي الْأَمْرِ، فَإِذَا عَزَمْتَ فَتَوَكَّلْ عَلَى اللَّهِ',
      'ayah_ref': 'سورة آل عمران: 159',
      'hadith': 'المستشار مؤتمن',
      'hadith_ref': 'رواه أبو داود',
      'quote': 'Plan with your mind. Act with your heart. Trust with your soul.',
    },
    {
      'ayah': 'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ',
      'ayah_ref': 'سورة الرحمن: 13',
      'hadith': 'انظروا إلى من هو أسفل منكم ولا تنظروا إلى من هو فوقكم',
      'hadith_ref': 'رواه مسلم',
      'quote': 'Count your blessings, not your problems.',
    },
    {
      'ayah': 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      'ayah_ref': 'سورة البقرة: 201',
      'hadith': 'خير الناس أنفعهم للناس',
      'hadith_ref': 'رواه الطبراني',
      'quote': 'Make this life count, so the next one shines brighter.',
    },
    {
      'ayah': 'وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ، عَلَيْهِ تَوَكَّلْتُ وَإِلَيْهِ أُنِيبُ',
      'ayah_ref': 'سورة هود: 88',
      'hadith': 'احفظ الله يحفظك، احفظ الله تجده تجاهك',
      'hadith_ref': 'رواه الترمذي',
      'quote': 'Every great achievement begins with a decision to try.',
    },
    {
      'ayah': 'وَلَا تَقُولَنَّ لِشَيْءٍ إِنِّي فَاعِلٌ ذَلِكَ غَدًا، إِلَّا أَن يَشَاءَ اللَّهُ',
      'ayah_ref': 'سورة الكهف: 23-24',
      'hadith': 'اغتنم خمسا قبل خمس: شبابك قبل هرمك، وصحتك قبل سقمك',
      'hadith_ref': 'رواه الحاكم',
      'quote': 'Do not wait. The time will never be just right.',
    },
    {
      'ayah': 'قُلْ إِنَّ صَلَاتِي وَنُسُكِي وَمَحْيَايَ وَمَمَاتِي لِلَّهِ رَبِّ الْعَالَمِينَ',
      'ayah_ref': 'سورة الأنعام: 162',
      'hadith': 'أفضل الذكر لا إله إلا الله، وأفضل الدعاء الحمد لله',
      'hadith_ref': 'رواه الترمذي',
      'quote': 'Live for a purpose greater than yourself.',
    },
    {
      'ayah': 'إِنَّ الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ كَانَتْ لَهُمْ جَنَّاتُ الْفِرْدَوْسِ نُزُلًا',
      'ayah_ref': 'سورة الكهف: 107',
      'hadith': 'إذا سألتم الله فاسألوه الفردوس، فإنه وسط الجنة وأعلى الجنة',
      'hadith_ref': 'رواه البخاري',
      'quote': 'Dream big. Work hard. Stay focused. Trust the journey.',
    },
    {
      'ayah': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      'ayah_ref': 'سورة الرعد: 28',
      'hadith': 'ما جلس قوم يذكرون الله إلا حفتهم الملائكة وغشيتهم الرحمة',
      'hadith_ref': 'رواه مسلم',
      'quote': 'Peace begins the moment you let Allah handle it.',
    },
    {
      'ayah': 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
      'ayah_ref': 'سورة البقرة: 153',
      'hadith': 'ما أعطي أحد عطاء خيرا وأوسع من الصبر',
      'hadith_ref': 'رواه البخاري',
      'quote': 'Great things never come from comfort zones.',
    },
  ];


  late Map<String, String> _todayMotivation;

  @override
  void initState() {
    super.initState();
    _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _pickMotivation();
    _loadData();
    AppState.instance.addListener(_loadData);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_loadData);
    super.dispose();
  }

  void _pickMotivation() {
    setState(() {
      _todayMotivation = _motivations[Random().nextInt(_motivations.length)];
    });
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
          onRefresh: () async {
            _pickMotivation();
            _loadData();
          },
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
                   Row(
                    children: [
                      const ThemeToggleButton(),
                      const SizedBox(width: 12),
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
