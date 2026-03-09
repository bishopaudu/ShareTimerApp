import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../viewmodels/timer_viewmodel.dart';
import '../viewmodels/participant_viewmodel.dart';
import '../services/timer_calculation_service.dart';
import '../utils/constants.dart';
import 'timer_detail_screen.dart';

/// Create Timer Screen
///
/// Allows users to create a new countdown timer with a title and duration.
/// Validates input and navigates to the timer detail screen on success.
class CreateTimerScreen extends StatefulWidget {
  const CreateTimerScreen({super.key});

  @override
  State<CreateTimerScreen> createState() => _CreateTimerScreenState();
}

class _CreateTimerScreenState extends State<CreateTimerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  int _hours = 0;
  int _minutes = 5;
  int _seconds = 0;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Create Timer',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onBackground,
      ),
      body: Consumer<TimerViewModel>(
        builder: (context, timerViewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title input
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIMER NAME',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _titleController,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. Boss Battle',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppConstants.errorEmptyTitle;
                              }
                              if (value.trim().length < 2) {
                                return 'Title must be at least 2 characters';
                              }
                              return null;
                            },
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Duration picker
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DURATION',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTimePicker(
                                label: 'HOURS',
                                value: _hours,
                                max: 23,
                                onChanged: (value) =>
                                    setState(() => _hours = value),
                                colorScheme: colorScheme,
                              ),
                              Text(
                                ':',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[300],
                                ),
                              ),
                              _buildTimePicker(
                                label: 'MINS',
                                value: _minutes,
                                max: 59,
                                onChanged: (value) =>
                                    setState(() => _minutes = value),
                                colorScheme: colorScheme,
                              ),
                              Text(
                                ':',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[300],
                                ),
                              ),
                              _buildTimePicker(
                                label: 'SECS',
                                value: _seconds,
                                max: 59,
                                onChanged: (value) =>
                                    setState(() => _seconds = value),
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer_rounded,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Total: ${TimerCalculationService.formatDurationHumanReadable(TimerCalculationService.toSeconds(hours: _hours, minutes: _minutes, seconds: _seconds))}',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (timerViewModel.error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              timerViewModel.error!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Create button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: timerViewModel.isLoading ? null : _createTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: colorScheme.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: timerViewModel.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'START TIMER',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                color: colorScheme.primary,
                onPressed: () {
                  if (value < max) {
                    onChanged(value + 1);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text(
                  value.toString().padLeft(2, '0'),
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [const FontFeature.tabularFigures()],
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                color: colorScheme.primary,
                onPressed: () {
                  if (value > 0) {
                    onChanged(value - 1);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createTimer() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Calculate total duration
    final durationSeconds = TimerCalculationService.toSeconds(
      hours: _hours,
      minutes: _minutes,
      seconds: _seconds,
    );

    // Validate duration
    if (durationSeconds < AppConstants.minTimerDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duration must be at least 1 second'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (durationSeconds > AppConstants.maxTimerDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duration cannot exceed 24 hours'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final timerViewModel = Provider.of<TimerViewModel>(context, listen: false);
    final participantViewModel = Provider.of<ParticipantViewModel>(
      context,
      listen: false,
    );

    final userId = participantViewModel.getUserId();

    // Create timer
    final timerId = await timerViewModel.createTimer(
      title: _titleController.text,
      durationSeconds: durationSeconds,
      creatorId: userId,
    );

    if (timerId != null && mounted) {
      // Save it locally to history using the correct provider instance
      await participantViewModel.addCreatedTimer(timerId);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.successTimerCreated),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to timer detail screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TimerDetailScreen(timerId: timerId),
        ),
      );
    }
  }
}
