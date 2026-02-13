import 'package:intl/intl.dart';

/// Timer Calculation Service
///
/// This service handles all time-related calculations for timers.
/// It uses UTC timestamps to avoid clock skew issues across devices.
class TimerCalculationService {
  /// Calculate remaining time in seconds from a timer's start time and duration
  ///
  /// This method uses the current UTC time to calculate the remaining time,
  /// which prevents issues with device clock differences.
  ///
  /// Returns 0 if the timer has finished.
  static int calculateRemainingSeconds({
    required DateTime startTime,
    required int durationSeconds,
  }) {
    final now = DateTime.now().toUtc();
    final endTime = startTime.add(Duration(seconds: durationSeconds));

    final difference = endTime.difference(now);

    if (difference.isNegative) {
      return 0; // Timer has finished
    }

    return difference.inSeconds;
  }

  /// Calculate the end time of a timer
  static DateTime calculateEndTime({
    required DateTime startTime,
    required int durationSeconds,
  }) {
    return startTime.add(Duration(seconds: durationSeconds));
  }

  /// Format seconds into HH:MM:SS format
  ///
  /// Examples:
  /// - 3661 seconds -> "01:01:01"
  /// - 125 seconds -> "00:02:05"
  /// - 0 seconds -> "00:00:00"
  static String formatDuration(int totalSeconds) {
    if (totalSeconds < 0) {
      totalSeconds = 0;
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Format seconds into a human-readable string
  ///
  /// Examples:
  /// - 3661 seconds -> "1 hour, 1 minute, 1 second"
  /// - 125 seconds -> "2 minutes, 5 seconds"
  /// - 3600 seconds -> "1 hour"
  static String formatDurationHumanReadable(int totalSeconds) {
    if (totalSeconds < 0) {
      totalSeconds = 0;
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final parts = <String>[];

    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
    }

    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
    }

    if (seconds > 0 || parts.isEmpty) {
      parts.add('$seconds ${seconds == 1 ? 'second' : 'seconds'}');
    }

    return parts.join(', ');
  }

  /// Format a DateTime to a readable string
  ///
  /// Example: "Feb 4, 2026 at 3:45 PM"
  static String formatDateTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return DateFormat('MMM d, y \'at\' h:mm a').format(localTime);
  }

  /// Format a DateTime to a time-only string
  ///
  /// Example: "3:45 PM"
  static String formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return DateFormat('h:mm a').format(localTime);
  }

  /// Check if a timer has finished
  static bool isTimerFinished({
    required DateTime startTime,
    required int durationSeconds,
  }) {
    return calculateRemainingSeconds(
          startTime: startTime,
          durationSeconds: durationSeconds,
        ) ==
        0;
  }

  /// Calculate the progress percentage of a timer (0.0 to 1.0)
  ///
  /// Returns 1.0 if the timer has finished.
  static double calculateProgress({
    required DateTime startTime,
    required int durationSeconds,
  }) {
    final remaining = calculateRemainingSeconds(
      startTime: startTime,
      durationSeconds: durationSeconds,
    );

    if (remaining == 0) {
      return 1.0;
    }

    final elapsed = durationSeconds - remaining;
    return elapsed / durationSeconds;
  }

  /// Convert hours, minutes, and seconds to total seconds
  static int toSeconds({
    required int hours,
    required int minutes,
    required int seconds,
  }) {
    return (hours * 3600) + (minutes * 60) + seconds;
  }

  /// Convert total seconds to hours, minutes, and seconds
  ///
  /// Returns a Map with 'hours', 'minutes', and 'seconds' keys
  static Map<String, int> fromSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return {'hours': hours, 'minutes': minutes, 'seconds': seconds};
  }
}
