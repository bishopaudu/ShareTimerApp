import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/timer_viewmodel.dart';
import '../viewmodels/participant_viewmodel.dart';
import 'widgets/timer_card.dart';
import 'widgets/custom_loader.dart';
import 'create_timer_screen.dart';
import 'join_timer_screen.dart';
import 'timer_detail_screen.dart';
import 'settings_screen.dart';

import '../services/notification_service.dart';

/// Home Screen - Main screen showing user's timers
///
/// Displays a list of all timers created by the user.
/// Provides options to create a new timer or join an existing one.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Request notification permissions after the app is fully loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerViewModel = Provider.of<TimerViewModel>(context, listen: false);
    final participantViewModel = Provider.of<ParticipantViewModel>(
      context,
      listen: false,
    );

    // Get current user ID
    final userId = participantViewModel.getUserId();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: StreamBuilder(
        stream: timerViewModel.getUserTimers(userId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoader(label: 'Loading Timers...');
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 80,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Oops!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Something went wrong loading your timers.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => (context as Element).markNeedsBuild(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('TRY AGAIN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final timers = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Gamified App Bar
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                backgroundColor: colorScheme.background,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text(
                    'My Timers',
                    style: GoogleFonts.montserrat(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 28, // Scaled down for title
                    ),
                  ),
                ),
                actions: [
                  // Settings Button
                  Consumer<ParticipantViewModel>(
                    builder: (context, vm, child) {
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Text(
                            vm.userProfile?.emoji ?? '⚙️',
                            style: const TextStyle(fontSize: 20),
                          ),
                          onPressed: () => _navigateToSettings(context),
                          tooltip: 'Settings',
                        ),
                      );
                    },
                  ),

                  // Join Button
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.login_rounded,
                        color: colorScheme.primary,
                      ),
                      onPressed: () => _navigateToJoinTimer(context),
                      tooltip: 'Join by Code',
                    ),
                  ),
                ],
              ),

              // Content
              if (timers.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.timer_outlined,
                              size: 80,
                              color: colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'No Timers Yet',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Create your first timer or join a friend\'s!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Action Buttons
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateToCreateTimer(context),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('CREATE NEW TIMER'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _navigateToJoinTimer(context),
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('JOIN EXISTING'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                side: BorderSide(
                                  color: colorScheme.secondary,
                                  width: 2,
                                ),
                                foregroundColor: colorScheme.secondary,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final timer = timers[index];
                      return TimerCard(
                        timer: timer,
                        onTap: () => _navigateToTimerDetail(context, timer.id),
                      );
                    }, childCount: timers.length),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTimer(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('NEW TIMER'),
        elevation: 4,
        highlightElevation: 8,
      ),
    );
  }

  void _navigateToCreateTimer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTimerScreen()),
    );
  }

  void _navigateToJoinTimer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const JoinTimerScreen()),
    );
  }

  void _navigateToTimerDetail(BuildContext context, String timerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerDetailScreen(timerId: timerId),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}
