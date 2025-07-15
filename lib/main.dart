import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'screens/web_home_screen.dart';
import 'screens/mobile_home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for premium appearance
  SystemChrome.setSystemUIOverlayStyle(AppTheme.lightSystemUiOverlay);
  
  runApp(const ChemicalProcessTrackerApp());
}

class ChemicalProcessTrackerApp extends StatelessWidget {
  const ChemicalProcessTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chemical Process Tracker - Enterprise Edition',
      theme: AppTheme.lightTheme,
      home: kIsWeb ? const WebHomeScreen() : const MobileHomeScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Prevent text scaling issues
          ),
          child: child!,
        );
      },
    );
  }
}