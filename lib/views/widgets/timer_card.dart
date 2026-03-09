import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../../models/timer_model.dart';
import '../../services/timer_calculation_service.dart';

/// Widget displaying a timer card in the list
///
/// Shows timer title, remaining time, and status.
/// Tappable to navigate to timer details.
class TimerCard extends StatelessWidget {
  final TimerModel timer;
  final VoidCallback onTap;
  final String? subtitle;

  const TimerCard({
    super.key,
    required this.timer,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = TimerCalculationService.calculateRemainingSeconds(
      startTime: timer.startTime,
      durationSeconds: timer.durationSeconds,
    );
    final isFinished = remainingSeconds == 0;
    final progress = TimerCalculationService.calculateProgress(
      startTime: timer.startTime,
      durationSeconds: timer.durationSeconds,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title and Status Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timer.title,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isFinished
                          ? Colors.grey.withOpacity(0.1)
                          : colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFinished
                            ? Colors.grey.withOpacity(0.3)
                            : colorScheme.secondary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFinished
                                ? Colors.grey
                                : colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isFinished ? 'FINISHED' : 'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isFinished
                                ? Colors.grey[700]
                                : colorScheme.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Countdown Display
              Center(
                child: Text(
                  isFinished
                      ? '00:00:00'
                      : TimerCalculationService.formatDuration(
                          remainingSeconds,
                        ),
                  style: GoogleFonts.robotoMono(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: isFinished ? Colors.grey : colorScheme.primary,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isFinished ? Colors.grey : colorScheme.primary,
                            isFinished
                                ? Colors.grey
                                : colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isFinished ? Colors.grey : colorScheme.primary)
                                    .withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Footer: Share Code
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Total: ${TimerCalculationService.formatDuration(timer.durationSeconds)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CODE: ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          timer.shareCode,
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
