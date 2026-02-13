import '../utils/constants.dart';

/// Input validation utilities
///
/// This file contains validation functions used throughout the app
/// to ensure data integrity and provide user-friendly error messages.

class Validators {
  /// Validate timer title
  /// Returns null if valid, error message if invalid
  static String? validateTimerTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return AppConstants.errorEmptyTitle;
    }

    if (title.trim().length < 2) {
      return 'Title must be at least 2 characters long.';
    }

    if (title.trim().length > 100) {
      return 'Title must be less than 100 characters.';
    }

    return null; // Valid
  }

  /// Validate timer duration in seconds
  /// Returns null if valid, error message if invalid
  static String? validateDuration(int? durationSeconds) {
    if (durationSeconds == null) {
      return AppConstants.errorInvalidDuration;
    }

    if (durationSeconds < AppConstants.minTimerDuration) {
      return 'Duration must be at least ${AppConstants.minTimerDuration} second.';
    }

    if (durationSeconds > AppConstants.maxTimerDuration) {
      return 'Duration cannot exceed 24 hours.';
    }

    return null; // Valid
  }

  /// Validate share code format
  /// Returns true if valid, false otherwise
  static bool isValidShareCode(String? code) {
    if (code == null || code.isEmpty) {
      return false;
    }

    // Share code should be exactly 6 alphanumeric characters
    final regex = RegExp(r'^[A-Z0-9]{6}$');
    return regex.hasMatch(code.toUpperCase());
  }

  /// Validate alarm title
  /// Returns null if valid, error message if invalid
  static String? validateAlarmTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Please enter an alarm title.';
    }

    if (title.trim().length > 50) {
      return 'Alarm title must be less than 50 characters.';
    }

    return null; // Valid
  }

  /// Validate alarm trigger time
  /// Returns null if valid, error message if invalid
  static String? validateAlarmTrigger(int? triggerSeconds, int timerDuration) {
    if (triggerSeconds == null) {
      return 'Please enter a valid trigger time.';
    }

    if (triggerSeconds < 0) {
      return 'Trigger time cannot be negative.';
    }

    if (triggerSeconds >= timerDuration) {
      return 'Alarm must trigger before the timer ends.';
    }

    return null; // Valid
  }

  /// Validate display name for participants
  /// Returns null if valid, error message if invalid
  static String? validateDisplayName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Please enter a display name.';
    }

    if (name.trim().length < 2) {
      return 'Display name must be at least 2 characters.';
    }

    if (name.trim().length > 30) {
      return 'Display name must be less than 30 characters.';
    }

    return null; // Valid
  }
}
