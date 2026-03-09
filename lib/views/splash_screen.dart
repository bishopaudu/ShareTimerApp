import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ntp/ntp.dart';
import '../services/notification_service.dart';
import '../viewmodels/participant_viewmodel.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start animation
    final animationFuture = _controller.forward();

    // Initialize services in parallel
    // We wrap this in a try-catch to ensure one failure doesn't block the app
    final servicesFuture = Future.wait([
      _initNotificationService(),
      _initParticipantViewModel(),
    ]);

    try {
      // Wait for both animation and services + minimum time
      // Add a timeout to prevent hanging indefinitely
      await Future.wait<dynamic>([
        animationFuture,
        servicesFuture,
        Future.delayed(const Duration(seconds: 2)), // Minimum splash time
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Splash initialization timed out');
          setState(() => _statusMessage = 'Starting up...');
          return [];
        },
      );
    } catch (e) {
      print('Error during splash initialization: $e');
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      if (mounted) {
        // Check if user has completed onboarding and profile setup
        final participantViewModel = Provider.of<ParticipantViewModel>(
          context,
          listen: false,
        );

        final isProfileSetup = participantViewModel.isProfileSetup;
        final hasSeenOnboarding = participantViewModel.hasSeenOnboarding;

        Widget nextScreen;
        if (isProfileSetup) {
          nextScreen = const HomeScreen();
        } else if (hasSeenOnboarding) {
          nextScreen = const WelcomeScreen();
        } else {
          nextScreen = const OnboardingScreen();
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => nextScreen,
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  Future<void> _initNotificationService() async {
    try {
      setState(() => _statusMessage = 'Setting up notifications...');
      print('Initializing NotificationService...');
      await NotificationService().initialize();
      print('NotificationService initialized.');
    } catch (e) {
      print('Failed to initialize NotificationService: $e');
    }
  }

  Future<void> _initParticipantViewModel() async {
    try {
      setState(() => _statusMessage = 'Loading user profile...');
      print('Initializing ParticipantViewModel...');
      if (!mounted) return;
      await Provider.of<ParticipantViewModel>(
        context,
        listen: false,
      ).initialize();

      // Initialize NTP time synchronization
      setState(() => _statusMessage = 'Syncing time...');
      await _initNtpSync();

      print('ParticipantViewModel initialized.');
    } catch (e) {
      print('Failed to initialize ParticipantViewModel: $e');
    }
  }

  Future<void> _initNtpSync() async {
    try {
      final int offset = await NTP.getNtpOffset(
        localTime: DateTime.now(),
        lookUpAddress: 'time.google.com',
        timeout: const Duration(seconds: 3),
      );
      print('NTP sync completed. Offset: ${offset}ms');
    } catch (e) {
      print('Failed to sync NTP time: $e');
      // Continue without NTP sync if it fails
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6200EA);
    const accentColor = Color(0xFF00BFA5);

    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.timer_outlined,
                    size: 60,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Animated Text
            FadeTransition(
              opacity: _opacityAnimation,
              child: Column(
                children: [
                  Text(
                    'ShareTime',
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Synchronized Timers',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: accentColor,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Status Text
                  Text(
                    _statusMessage,
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
