import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/shared_alarm_model.dart';
import '../models/shared_alarm_participant_model.dart';
import '../models/user_profile_model.dart';
import '../services/firestore_alarm_service.dart';
import '../services/notification_service.dart';
import '../utils/validators.dart';

/// ViewModel for Shared Alarm operations
class SharedAlarmViewModel extends ChangeNotifier {
  final FirestoreAlarmService _firestoreService = FirestoreAlarmService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  // State variables
  bool _isLoading = false;
  String? _error;
  SharedAlarmModel? _currentAlarm;
  StreamSubscription? _alarmSubscription;
  StreamSubscription? _participantsSubscription;
  List<SharedAlarmParticipantModel> _participants = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  SharedAlarmModel? get currentAlarm => _currentAlarm;
  List<SharedAlarmParticipantModel> get participants => _participants;

  /// Generate a random 6-character share code
  String _generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  /// Create a new shared alarm
  Future<String?> createAlarm({
    required String title,
    String? description,
    required DateTime triggerTime,
    int? maxParticipants,
    required UserProfileModel userProfile,
  }) async {
    // Validate inputs
    final titleError = Validators.validateAlarmTitle(title);
    if (titleError != null) {
      _error = titleError;
      notifyListeners();
      return null;
    }

    final triggerError = Validators.validateSharedAlarmTrigger(triggerTime);
    if (triggerError != null) {
      _error = triggerError;
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now().toUtc();
      final alarmId = _uuid.v4();
      final shareCode = _generateShareCode();

      // Ensure trigger time is in UTC for unified sync
      final utcTriggerTime = triggerTime.toUtc();

      final alarm = SharedAlarmModel(
        id: alarmId,
        title: title.trim(),
        description: description?.trim(),
        creatorId: userProfile.id,
        triggerTime: utcTriggerTime,
        createdAt: now,
        maxParticipants: maxParticipants,
        status: SharedAlarmStatus.active,
        shareCode: shareCode,
      );

      // Save to Firestore
      final createdAlarmId = await _firestoreService.createSharedAlarm(alarm);

      // Add creator as the first participant automatically
      final creatorParticipant = SharedAlarmParticipantModel(
        userId: userProfile.id,
        displayName: userProfile.displayName,
        emoji: userProfile.emoji,
        joinedAt: now,
      );

      await _firestoreService.joinSharedAlarm(
        createdAlarmId,
        creatorParticipant,
      );

      // Schedule local notification
      _scheduleLocalNotificationForAlarm(createdAlarmId, alarm);

      _isLoading = false;
      notifyListeners();
      return createdAlarmId;
    } catch (e) {
      _error = 'Failed to create alarm: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Join an existing shared alarm by share code
  Future<String?> joinAlarmWithCode(
    String shareCode,
    UserProfileModel userProfile,
  ) async {
    if (!Validators.isValidShareCode(shareCode)) {
      _error = 'Invalid share code format.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final alarm = await _firestoreService.getSharedAlarmByShareCode(
        shareCode,
      );

      if (alarm == null) {
        _error = 'Alarm not found.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      return await _joinAlarmProcess(alarm, userProfile);
    } catch (e) {
      _error = 'Failed to join alarm: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Inner join logic
  Future<String?> _joinAlarmProcess(
    SharedAlarmModel alarm,
    UserProfileModel userProfile,
  ) async {
    try {
      final participant = SharedAlarmParticipantModel(
        userId: userProfile.id,
        displayName: userProfile.displayName,
        emoji: userProfile.emoji,
        joinedAt: DateTime.now().toUtc(),
      );

      await _firestoreService.joinSharedAlarm(alarm.id, participant);

      // Schedule local notification
      _scheduleLocalNotificationForAlarm(alarm.id, alarm);

      _isLoading = false;
      notifyListeners();
      return alarm.id;
    } catch (e) {
      _error = e.toString().contains('Exception:')
          ? e.toString().split('Exception: ')[1]
          : 'Failed to join alarm: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Leave an alarm
  Future<bool> leaveAlarm(String alarmId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.leaveSharedAlarm(alarmId, userId);
      _cancelLocalNotificationForAlarm(alarmId);

      if (_currentAlarm?.id == alarmId) {
        _clearCurrentSession();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to leave alarm: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel an alarm (creator only)
  Future<bool> cancelAlarm(String alarmId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.cancelSharedAlarm(alarmId);
      // If we are currently viewing it, our stream will pick up the 'cancelled' status
      _cancelLocalNotificationForAlarm(alarmId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to cancel alarm: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load a specific alarm and subscribe to its real-time updates
  void loadAlarm(String alarmId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Cancel existing subscriptions
    _alarmSubscription?.cancel();
    _participantsSubscription?.cancel();

    // Subscribe to alarm updates
    _alarmSubscription = _firestoreService
        .getSharedAlarmStream(alarmId)
        .listen(
          (alarm) {
            _currentAlarm = alarm;

            // Ensure local notifications reflect accurate status
            if (alarm != null && alarm.status != SharedAlarmStatus.active) {
              _cancelLocalNotificationForAlarm(alarmId);
            }

            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            _error = 'Failed to load alarm details: $e';
            _isLoading = false;
            notifyListeners();
          },
        );

    // Subscribe to participants updates
    _participantsSubscription = _firestoreService
        .getSharedAlarmParticipantsStream(alarmId)
        .listen(
          (participantsList) {
            _participants = participantsList;
            notifyListeners();
          },
          onError: (e) {
            print('Error loading participants: $e');
          },
        );
  }

  /// Get stream of user's alarms
  Stream<List<SharedAlarmModel>> getUserSharedAlarms(String userId) {
    return _firestoreService.getUserSharedAlarms(userId);
  }

  // ==================== HELPER METHODS ====================

  /// Generate deterministic notification ID from UUID
  int _generateNotificationId(String id) {
    return id.hashCode.abs() % 100000;
  }

  /// Schedules notification logic internal proxy
  void _scheduleLocalNotificationForAlarm(
    String alarmId,
    SharedAlarmModel alarm,
  ) {
    if (alarm.status == SharedAlarmStatus.active) {
      _notificationService.scheduleSharedAlarmNotification(
        notificationId: _generateNotificationId(alarmId),
        alarmTitle: alarm.title,
        triggerTimeUtc: alarm.triggerTime,
        alarmId: alarmId,
      );
    }
  }

  /// Cancel corresponding local notification internal proxy
  void _cancelLocalNotificationForAlarm(String alarmId) {
    _notificationService.cancelNotification(_generateNotificationId(alarmId));
  }

  void _clearCurrentSession() {
    _alarmSubscription?.cancel();
    _participantsSubscription?.cancel();
    _currentAlarm = null;
    _participants = [];
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _clearCurrentSession();
    super.dispose();
  }
}
