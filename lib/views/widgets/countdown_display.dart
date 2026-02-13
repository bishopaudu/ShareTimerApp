import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../models/timer_model.dart';
import '../../services/timer_calculation_service.dart';

/// Widget displaying a large countdown timer
///
/// Updates every second to show the current remaining time.
/// Displays "FINISHED" when the timer reaches zero.
class CountdownDisplay extends StatefulWidget {
  final TimerModel timer;

  const CountdownDisplay({super.key, required this.timer});

  @override
  State<CountdownDisplay> createState() => _CountdownDisplayState();
}

class _CountdownDisplayState extends State<CountdownDisplay> {
  Timer? _updateTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();

    // Update every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  @override
  void didUpdateWidget(CountdownDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timer.id != widget.timer.id) {
      _updateRemainingTime();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
    final remaining = TimerCalculationService.calculateRemainingSeconds(
      startTime: widget.timer.startTime,
      durationSeconds: widget.timer.durationSeconds,
    );

    if (mounted) {
      setState(() {
        _remainingSeconds = remaining;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = _remainingSeconds == 0;
    final formattedTime = isFinished
        ? 'DONE'
        : TimerCalculationService.formatDuration(_remainingSeconds);

    final progress = TimerCalculationService.calculateProgress(
      startTime: widget.timer.startTime,
      durationSeconds: widget.timer.durationSeconds,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer title
          Text(
            widget.timer.title.toUpperCase(),
            style: TextStyle(
              color: colorScheme.secondary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Circular Progress
          CircularPercentIndicator(
            radius: 120.0,
            lineWidth: 15.0,
            animation: true,
            animateFromLastPercent: true,
            percent: progress,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isFinished ? 40.0 : 48.0,
                    color: isFinished ? Colors.grey : colorScheme.primary,
                  ),
                ),
                if (!isFinished)
                  Text(
                    'REMAINING',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.0,
                      color: Colors.grey[500],
                      letterSpacing: 2,
                    ),
                  ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.grey[100]!,
            progressColor: isFinished ? Colors.grey : colorScheme.primary,
            widgetIndicator: null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
