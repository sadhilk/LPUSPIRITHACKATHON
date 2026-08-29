import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/schedule_screen.dart';
import 'services/device_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0E12),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const SmartHomeApp());
}

class AppColors {
  static const background = Color(0xFF09120E);               // Deep Obsidian Forest
  static const surfaceContainerLowest = Color(0xFF050A08);     // Pure Deep Base
  static const surfaceContainerLow = Color(0xFF0E1A14);        // Rich Emerald Dark
  static const surfaceContainer = Color(0xFF14241C);           // Deep Jade Glass
  static const surfaceContainerHigh = Color(0xFF1B2F25);        // High Emerald Surface
  static const surfaceContainerHighest = Color(0xFF243B30);     // Highest Emerald Surface
  static const surfaceBright = Color(0xFF2D483B);            // Bright Jade Highlight
  static const onSurface = Color(0xFFFAF8F5);                // Silk Champagne White
  static const onSurfaceVariant = Color(0xFFC7D3C6);         // Soft Sage Silver
  static const outline = Color(0xFF6B8E78);                  // Muted Emerald Outline
  static const outlineVariant = Color(0xFF284234);           // Dark Emerald Border
  static const primary = Color(0xFFE6C687);                  // Champagne Gold
  static const solarMuted = Color(0xFFD4AF37);               // Royal Imperial Gold
  static const crimsonMuted = Color(0xFFE05252);             // Crimson Amber
  static const slateGradientStop = Color(0xFF1C3328);        // Deep Forest Stop
  static const greenActive = Color(0xFF34D399);              // Royal Emerald Mint
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartHome AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          background: AppColors.background,
          surface: AppColors.surfaceContainerLow,
          primary: AppColors.primary,
          onSurface: AppColors.onSurface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme),
        dialogBackgroundColor: AppColors.surfaceContainerLow,
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surfaceContainerLow,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final DeviceService _deviceService = DeviceService();
  late AnimationController _navAnimController;

  @override
  void initState() {
    super.initState();
    _deviceService.connect();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _deviceService.disconnect();
    _navAnimController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(deviceService: _deviceService),
      AnalyticsScreen(deviceService: _deviceService),
      ScheduleScreen(deviceService: _deviceService),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _LuminaBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

class _LuminaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LuminaBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(index: 0, currentIndex: currentIndex, icon: Icons.home_rounded, label: 'Home', onTap: onTap),
              _NavItem(index: 1, currentIndex: currentIndex, icon: Icons.insights_rounded, label: 'Analytics', onTap: onTap),
              _NavItem(index: 2, currentIndex: currentIndex, icon: Icons.tune_rounded, label: 'Schedule', onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceContainerHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isActive ? AppColors.solarMuted : AppColors.outlineVariant,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.05,
                color: isActive ? AppColors.solarMuted : AppColors.outlineVariant,
                fontFamily: 'Montserrat',
              ),
              child: Text(label.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }
}
