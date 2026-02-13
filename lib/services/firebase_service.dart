import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timer_model.dart';
import '../models/participant_model.dart';
import '../models/alarm_model.dart';
import '../utils/constants.dart';

/// Firebase Service for Firestore operations
///
/// This service handles all interactions with Firebase Firestore.
/// It follows the Repository pattern and provides a clean API
/// for the ViewModels to interact with the database.
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== TIMER OPERATIONS ====================

  /// Create a new timer in Firestore
  /// Returns the created timer's ID
  Future<String> createTimer(TimerModel timer) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.timersCollection)
          .add(timer.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create timer: $e');
    }
  }

  /// Get a timer by ID
  Future<TimerModel?> getTimerById(String timerId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return TimerModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get timer: $e');
    }
  }

  /// Get a timer by share code
  Future<TimerModel?> getTimerByShareCode(String shareCode) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.timersCollection)
          .where('shareCode', isEqualTo: shareCode.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return TimerModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to find timer: $e');
    }
  }

  /// Get real-time stream of a timer
  Stream<TimerModel?> getTimerStream(String timerId) {
    return _firestore
        .collection(AppConstants.timersCollection)
        .doc(timerId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return null;
          }
          return TimerModel.fromFirestore(doc);
        });
  }

  /// Get all timers created by a specific user
  Stream<List<TimerModel>> getUserTimers(String userId) {
    return _firestore
        .collection(AppConstants.timersCollection)
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TimerModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Update timer status
  Future<void> updateTimerStatus(String timerId, TimerStatus status) async {
    try {
      await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .update({'status': status.toString().split('.').last});
    } catch (e) {
      throw Exception('Failed to update timer status: $e');
    }
  }

  /// Delete a timer
  Future<void> deleteTimer(String timerId) async {
    try {
      // Delete all participants
      final participantsSnapshot = await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .collection(AppConstants.participantsCollection)
          .get();

      for (var doc in participantsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all alarms
      final alarmsSnapshot = await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .collection(AppConstants.alarmsCollection)
          .get();

      for (var doc in alarmsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the timer
      await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete timer: $e');
    }
  }

  // ==================== PARTICIPANT OPERATIONS ====================

  /// Add a participant to a timer
  Future<void> addParticipant(
    String timerId,
    ParticipantModel participant,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .collection(AppConstants.participantsCollection)
          .doc(participant.userId)
          .set(participant.toFirestore());
    } catch (e) {
      throw Exception('Failed to add participant: $e');
    }
  }

  /// Remove a participant from a timer
  Future<void> removeParticipant(String timerId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .collection(AppConstants.participantsCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove participant: $e');
    }
  }

  /// Update participant's last seen timestamp (for presence detection)
  Future<void> updateParticipantPresence(String timerId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .collection(AppConstants.participantsCollection)
          .doc(userId)
          .update({'lastSeen': FieldValue.serverTimestamp()});
    } catch (e) {
      // Silently fail - presence updates are not critical
      print('Failed to update presence: $e');
    }
  }

  /// Get real-time stream of participants for a timer
  Stream<List<ParticipantModel>> getParticipantsStream(String timerId) {
    return _firestore
        .collection(AppConstants.timersCollection)
        .doc(timerId)
        .collection(AppConstants.participantsCollection)
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ParticipantModel.fromFirestore(doc))
              .where((participant) => participant.isActive())
              .toList();
        });
  }

  /// Remove inactive participants (cleanup utility)
  Future<void> removeInactiveParticipants(String timerId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .collection(AppConstants.participantsCollection)
          .get();

      for (var doc in snapshot.docs) {
        final participant = ParticipantModel.fromFirestore(doc);
        if (!participant.isActive()) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('Failed to remove inactive participants: $e');
    }
  }

  // ==================== ALARM OPERATIONS ====================

  /// Add an alarm to a timer
  Future<String> addAlarm(String timerId, AlarmModel alarm) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .collection(AppConstants.alarmsCollection)
          .add(alarm.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add alarm: $e');
    }
  }

  /// Remove an alarm from a timer
  Future<void> removeAlarm(String timerId, String alarmId) async {
    try {
      await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .collection(AppConstants.alarmsCollection)
          .doc(alarmId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove alarm: $e');
    }
  }

  /// Get real-time stream of alarms for a timer
  Stream<List<AlarmModel>> getAlarmsStream(String timerId) {
    return _firestore
        .collection(AppConstants.timersCollection)
        .doc(timerId)
        .collection(AppConstants.alarmsCollection)
        .orderBy('triggerSeconds')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AlarmModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get all alarms for a timer (one-time fetch)
  Future<List<AlarmModel>> getAlarms(String timerId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.timersCollection)
          .doc(timerId)
          .collection(AppConstants.alarmsCollection)
          .orderBy('triggerSeconds')
          .get();

      return snapshot.docs.map((doc) => AlarmModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get alarms: $e');
    }
  }
}
