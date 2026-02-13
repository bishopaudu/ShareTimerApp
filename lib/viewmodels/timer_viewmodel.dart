import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/timer_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/timer_calculation_service.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';

/// ViewModel for Timer operations
///
/// This ViewModel follows the MVVM pattern and manages all timer-related
/// business logic and state. It uses ChangeNotifier to notify the UI of changes.
class TimerViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  // State variables
  bool _isLoading = false;
  String? _error;
  TimerModel? _currentTimer;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  TimerModel? get currentTimer => _currentTimer;

  /// Create a new timer
  ///
  /// Validates input, generates a unique share code, and saves to Firestore.
  /// Also schedules a notification for when the timer ends.
  Future<String?> createTimer({
    required String title,
    required int durationSeconds,
    required String creatorId,
  }) async {
    // Validate inputs
    final titleError = Validators.validateTimerTitle(title);
    if (titleError != null) {
      _error = titleError;
      notifyListeners();
      return null;
    }

    final durationError = Validators.validateDuration(durationSeconds);
    if (durationError != null) {
      _error = durationError;
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Generate unique share code
      final shareCode = _generateShareCode();

      // Create timer with UTC timestamp
      final now = DateTime.now().toUtc();
      final endTime = TimerCalculationService.calculateEndTime(
        startTime: now,
        durationSeconds: durationSeconds,
      );

      final timer = TimerModel(
        id: _uuid.v4(),
        title: title.trim(),
        durationSeconds: durationSeconds,
        startTime: now,
        endTime: endTime,
        status: TimerStatus.active,
        creatorId: creatorId,
        shareCode: shareCode,
        createdAt: now,
      );

      // Save to Firestore
      final timerId = await _firebaseService.createTimer(timer);

      // Schedule end notification
      await _notificationService.scheduleTimerEndNotification(
        notificationId: timerId.hashCode,
        timerTitle: title,
        endTime: endTime,
        timerId: timerId,
      );

      _isLoading = false;
      notifyListeners();

      return timerId;
    } catch (e) {
      _error = 'Failed to create timer: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Join a timer using a share code
  ///
  /// Validates the share code and retrieves the timer from Firestore.
  Future<TimerModel?> joinTimer(String shareCode) async {
    // Validate share code format
    if (!Validators.isValidShareCode(shareCode)) {
      _error = AppConstants.errorInvalidShareCode;
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final timer = await _firebaseService.getTimerByShareCode(shareCode);

      if (timer == null) {
        _error = AppConstants.errorTimerNotFound;
        _isLoading = false;
        notifyListeners();
        return null;
      }

      _currentTimer = timer;
      _isLoading = false;
      notifyListeners();

      return timer;
    } catch (e) {
      _error = 'Failed to join timer: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get a timer by ID
  Future<TimerModel?> getTimer(String timerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final timer = await _firebaseService.getTimerById(timerId);

      if (timer == null) {
        _error = AppConstants.errorTimerNotFound;
        _isLoading = false;
        notifyListeners();
        return null;
      }

      _currentTimer = timer;
      _isLoading = false;
      notifyListeners();

      return timer;
    } catch (e) {
      _error = 'Failed to get timer: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get a stream of a timer for real-time updates
  Stream<TimerModel?> getTimerStream(String timerId) {
    return _firebaseService.getTimerStream(timerId);
  }

  /// Get all timers created by a user
  Stream<List<TimerModel>> getUserTimers(String userId) {
    return _firebaseService.getUserTimers(userId);
  }

  /// Update timer status
  Future<void> updateTimerStatus(String timerId, TimerStatus status) async {
    try {
      await _firebaseService.updateTimerStatus(timerId, status);
    } catch (e) {
      _error = 'Failed to update timer status: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Delete a timer
  Future<bool> deleteTimer(String timerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.deleteTimer(timerId);

      // Cancel associated notification
      await _notificationService.cancelNotification(timerId.hashCode);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete timer: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Calculate remaining time for a timer
  int calculateRemainingSeconds(TimerModel timer) {
    return TimerCalculationService.calculateRemainingSeconds(
      startTime: timer.startTime,
      durationSeconds: timer.durationSeconds,
    );
  }

  /// Format duration to HH:MM:SS
  String formatDuration(int seconds) {
    return TimerCalculationService.formatDuration(seconds);
  }

  /// Check if a timer has finished
  bool isTimerFinished(TimerModel timer) {
    return TimerCalculationService.isTimerFinished(
      startTime: timer.startTime,
      durationSeconds: timer.durationSeconds,
    );
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Generate a random 6-character alphanumeric share code
  String _generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      AppConstants.shareCodeLength,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
