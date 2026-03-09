import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'viewmodels/timer_viewmodel.dart';
import 'viewmodels/participant_viewmodel.dart';
import 'viewmodels/alarm_viewmodel.dart';
import 'viewmodels/shared_alarm_viewmodel.dart';

import 'views/splash_screen.dart';
import 'views/home_screen.dart';

/// Main entry point for the Shared Timer App
///
/// This app follows MVVM architecture:
/// - Models: Data structures (TimerModel, ParticipantModel, AlarmModel)
/// - Views: UI screens and widgets
/// - ViewModels: Business logic and state management using Provider
/// - Services: Firebase, Notifications, and utility services
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (keep this as it's usually fast enough, or move to Splash if needed)
  await Firebase.initializeApp();

  runApp(const SharedTimerApp());
}

/// Root widget of the application
///
/// Sets up Provider for state management and configures the app theme.
class SharedTimerApp extends StatelessWidget {
  const SharedTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Timer ViewModel
        ChangeNotifierProvider(create: (_) => TimerViewModel()),

        // Participant ViewModel
        ChangeNotifierProvider(create: (_) => ParticipantViewModel()),

        // Alarm ViewModel
        ChangeNotifierProvider(create: (_) => AlarmViewModel()),

        // Shared Alarm ViewModel
        ChangeNotifierProvider(create: (_) => SharedAlarmViewModel()),
      ],
      child: MaterialApp(
        title: 'ShareTime',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,

          // Color scheme - Vibrant & "Gamified"
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6200EA), // Deep Purple Accent
            brightness: Brightness.light,
            primary: const Color(0xFF6200EA),
            secondary: const Color(0xFF00BFA5), // Teal Accent
            tertiary: const Color(0xFFFFAB00), // Amber Accent
            background: const Color(0xFFF5F5F7),
          ),

          // Typography
          textTheme: GoogleFonts.montserratTextTheme(
            Theme.of(context).textTheme,
          ),

          // App Bar Theme
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF1D1D1D),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1D1D),
            ),
          ),

          // Card Theme
          cardTheme: CardThemeData(
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
          ),

          // Elevated Button Theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6200EA),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFF6200EA).withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // Outlined Button Theme
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6200EA),
              side: const BorderSide(color: Color(0xFF6200EA), width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // Input Decoration Theme
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6200EA), width: 2),
            ),
            contentPadding: const EdgeInsets.all(20),
            labelStyle: GoogleFonts.montserrat(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),

          // Floating Action Button Theme
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF6200EA),
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const SplashScreen(),
        routes: {'/home': (context) => const HomeScreen()},
      ),
    );
  }
}
