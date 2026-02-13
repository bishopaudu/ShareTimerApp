/// Application-wide constants
///
/// This file contains all constant values used throughout the app
/// to maintain consistency and make updates easier.

class AppConstants {
  // Firestore Collection Names
  static const String timersCollection = 'timers';
  static const String participantsCollection = 'participants';
  static const String alarmsCollection = 'alarms';

  // Notification Channel IDs
  static const String timerChannelId = 'timer_notifications';
  static const String timerChannelName = 'Timer Notifications';
  static const String timerChannelDescription =
      'Notifications for timer events';

  static const String alarmChannelId = 'alarm_notifications';
  static const String alarmChannelName = 'Alarm Notifications';
  static const String alarmChannelDescription =
      'Notifications for timer alarms';

  // Default Values
  static const int defaultTimerDuration = 300; // 5 minutes in seconds
  static const int maxTimerDuration = 86400; // 24 hours in seconds
  static const int minTimerDuration = 1; // 1 second

  static const int presenceUpdateInterval =
      30; // Update presence every 30 seconds
  static const int presenceTimeout =
      120; // Consider user inactive after 2 minutes

  static const int shareCodeLength = 6;

  // Error Messages
  static const String errorNetworkUnavailable =
      'Network connection unavailable. Please check your internet connection.';
  static const String errorTimerNotFound =
      'Timer not found or has been deleted.';
  static const String errorInvalidShareCode =
      'Invalid share code. Please check and try again.';
  static const String errorTimerExpired = 'This timer has already finished.';
  static const String errorInvalidDuration = 'Please enter a valid duration.';
  static const String errorEmptyTitle = 'Please enter a timer title.';
  static const String errorPermissionDenied =
      'Notification permission denied. You won\'t receive alarm notifications.';
  static const String errorGeneric = 'An error occurred. Please try again.';

  // Success Messages
  static const String successTimerCreated = 'Timer created successfully!';
  static const String successTimerJoined = 'Joined timer successfully!';
  static const String successAlarmAdded = 'Alarm added successfully!';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Timer Display
  static const String timerFinishedText = 'FINISHED';
  static const String timerActiveText = 'Active';
  static const String timerPausedText = 'Paused';
}
