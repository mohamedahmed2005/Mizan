import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'services/storage_service.dart';
import 'services/app_state.dart';
import 'services/prayer_api_service.dart';
import 'models/prayer_model.dart';
import 'theme/app_theme.dart';
import 'theme/responsive_utils.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/study_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/statistics_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  AppState.instance.initFromStorage();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: AppState.instance.isDarkMode ? Brightness.light : Brightness.dark,
    ),
  );
  runApp(const MizanApp());
}

class MizanApp extends StatelessWidget {
  const MizanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        // Update the status bar color seamlessly when theme changes
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: AppState.instance.isDarkMode ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp(
          title: 'Mizan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.currentTheme,
          themeAnimationDuration: const Duration(milliseconds: 400),
          themeAnimationCurve: Curves.easeInOut,
          home: Builder(
            builder: (context) => SplashScreen(
              onFinished: () {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
                    transitionDuration: const Duration(milliseconds: 800),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      final curveAnim = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOutCubic,
                      );
                      return FadeTransition(
                        opacity: curveAnim,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curveAnim),
                          child: child,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _prevIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.mosque_rounded, label: 'Prayer'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Study'),
    _NavItem(icon: Icons.self_improvement_rounded, label: 'Habits'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Stats'),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    PrayerScreen(),
    StudyScreen(),
    HabitsScreen(),
    StatisticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    // Rebuild navbar when theme changes
    AppState.instance.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onThemeChange);
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    double? lat;
    double? lng;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium)
          );
          lat = position.latitude;
          lng = position.longitude;

          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              String city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? '';
              String country = place.country ?? '';
              
              if (city.isNotEmpty && country.isNotEmpty) {
                PrayerNames.currentLocation = '$city, $country';
              } else if (city.isNotEmpty) {
                PrayerNames.currentLocation = city;
              } else if (country.isNotEmpty) {
                PrayerNames.currentLocation = country;
              } else {
                PrayerNames.currentLocation = 'Unknown Location';
              }
            }
          } catch (e) {
            debugPrint("Error reverse geocoding: $e");
            PrayerNames.currentLocation = 'Location Found';
          }
        } else {
          // If denied, default to Cairo immediately
          PrayerNames.currentLocation = 'Cairo, Egypt';
        }
      } else {
        PrayerNames.currentLocation = 'Cairo, Egypt';
      }
    } catch (e) {
      debugPrint("Error requesting location: $e");
      PrayerNames.currentLocation = 'Cairo, Egypt';
    }

    final times = await PrayerApiService.fetchPrayerTimes(lat: lat, lng: lng);
    if (mounted) {
      if (times != null && times.length == 5) {
        PrayerNames.times = times;
      } else {
        // null means API failed (likely no internet)
        PrayerNames.currentLocation = 'Offline';
      }
      AppState.instance.notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          // Determine slide direction based on nav movement
          final goingRight = _currentIndex >= _prevIndex;
          final slideIn = Tween<Offset>(
            begin: Offset(goingRight ? 0.06 : -0.06, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideIn, child: child),
          );
        },
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previous,
            if (current != null) current,
          ],
        ),
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) => _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    final hPad = R.pd(context);
    final iconSize = R.sp(context, 24);
    final labelSize = R.sp(context, 10);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad * 0.4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = _currentIndex == i;
              return GestureDetector(
                onTap: () {
                  if (_currentIndex != i) {
                    setState(() {
                      _prevIndex = _currentIndex;
                      _currentIndex = i;
                    });
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                      horizontal: hPad * 0.6, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.teal.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          item.icon,
                          color: selected
                              ? AppColors.teal
                              : AppColors.textMuted,
                          size: iconSize,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.poppins(
                          color: selected
                              ? AppColors.teal
                              : AppColors.textMuted,
                          fontSize: labelSize,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}