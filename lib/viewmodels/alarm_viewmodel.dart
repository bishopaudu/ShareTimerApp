import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm_model.dart';
import '../models/timer_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../utils/validators.dart';

/// ViewModel for Alarm operations
///
/// This ViewModel manages alarm-related business logic including
/// creating alarms, scheduling notifications, and real-time alarm lists.
class AlarmViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  // State variables
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Add an alarm to a timer
  ///
  /// Validates input, saves to Firestore, and schedules a local notification.
  Future<bool> addAlarm({
    required String timerId,
    required TimerModel timer,
    required String title,
    required int triggerSeconds,
    required String createdBy,
  }) async {
    // Validate alarm title
    final titleError = Validators.validateAlarmTitle(title);
    if (titleError != null) {
      _error = titleError;
      notifyListeners();
      return false;
    }

    // Validate trigger time
    final triggerError = Validators.validateAlarmTrigger(
      triggerSeconds,
      timer.durationSeconds,
    );
    if (triggerError != null) {
      _error = triggerError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now().toUtc();
      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      final alarm = AlarmModel(
        id: _uuid.v4(),
        timerId: timerId,
        title: title.trim(),
        triggerSeconds: triggerSeconds,
        notificationId: notificationId,
        createdAt: now,
        createdBy: createdBy,
      );

      // Save to Firestore
      final alarmId = await _firebaseService.addAlarm(timerId, alarm);

      // Schedule notification
      final triggerTime = alarm.getTriggerTime(timer.startTime);
      await _notificationService.scheduleAlarmNotification(
        notificationId: notificationId,
        alarmTitle: title,
        triggerTime: triggerTime,
        timerId: timerId,
        alarmId: alarmId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add alarm: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove an alarm from a timer
  ///
  /// Deletes from Firestore and cancels the scheduled notification.
  Future<bool> removeAlarm({
    required String timerId,
    required String alarmId,
    required int notificationId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Remove from Firestore
      await _firebaseService.removeAlarm(timerId, alarmId);

      // Cancel notification
      await _notificationService.cancelNotification(notificationId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to remove alarm: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get a stream of alarms for a timer
  ///
  /// This provides real-time updates of all alarms for a timer.
  Stream<List<AlarmModel>> getAlarmsStream(String timerId) {
    return _firebaseService.getAlarmsStream(timerId);
  }

  /// Get all alarms for a timer (one-time fetch)
  Future<List<AlarmModel>> getAlarms(String timerId) async {
    try {
      return await _firebaseService.getAlarms(timerId);
    } catch (e) {
      _error = 'Failed to get alarms: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  /// Schedule notifications for all alarms of a timer
  ///
  /// This is useful when a user joins a timer and needs to
  /// schedule notifications for existing alarms.
  Future<void> scheduleAllAlarmNotifications({
    required String timerId,
    required TimerModel timer,
  }) async {
    try {
      final alarms = await _firebaseService.getAlarms(timerId);

      for (final alarm in alarms) {
        // Only schedule if the alarm hasn't triggered yet
        if (!alarm.hasTriggered(timer.startTime)) {
          final triggerTime = alarm.getTriggerTime(timer.startTime);
          await _notificationService.scheduleAlarmNotification(
            notificationId: alarm.notificationId,
            alarmTitle: alarm.title,
            triggerTime: triggerTime,
            timerId: timerId,
            alarmId: alarm.id,
          );
        }
      }
    } catch (e) {
      print('Failed to schedule alarm notifications: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
