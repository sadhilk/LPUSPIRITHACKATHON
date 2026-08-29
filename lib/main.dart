import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'services/device_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF050A08),
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

class SmartHomeApp extends StatefulWidget {
  const SmartHomeApp({super.key});

  @override
  State<SmartHomeApp> createState() => _SmartHomeAppState();
}

class _SmartHomeAppState extends State<SmartHomeApp> {
  final DeviceService _deviceService = DeviceService();

  @override
  void initState() {
    super.initState();
    _deviceService.connect();
  }

  @override
  void dispose() {
    _deviceService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bulb AI',
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
      ),
      home: HomeScreen(deviceService: _deviceService),
    );
  }
}


