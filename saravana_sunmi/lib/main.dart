import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_id/android_id.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/scan_print_provider.dart';
import 'screens/home_screen.dart';
import 'screens/config_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock orientation to portrait — handheld device
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ScanPrintProvider(),
      child: const SaravanaApp(),
    ),
  );
}

class SaravanaApp extends StatelessWidget {
  const SaravanaApp({super.key});

  Future<bool> _initializeAndCheckConfig() async {
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        debugPrint('=== DEVICE INFO: ${androidInfo.data} ===');
        
        const androidIdPlugin = AndroidId();
        final String? androidId = await androidIdPlugin.getId();
        debugPrint('=== SECURE DEVICE ID (SID / ANDROID_ID): $androidId ===');
      } catch (e) {
        debugPrint('=== FAILED TO GET DEVICE INFO: $e ===');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_configured') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brite_meter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      ),
      home: FutureBuilder<bool>(
        future: _initializeAndCheckConfig(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF2F2F7),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF512DA8)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Initializing application...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF512DA8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data == true) {
            return const HomeScreen();
          }
          return const ConfigScreen();
        },
      ),
    );
  }
}