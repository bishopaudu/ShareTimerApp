import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shared_alarm_model.dart';
import '../models/shared_alarm_participant_model.dart';
import '../utils/constants.dart';

/// Firebase Service for Shared Alarms operations
class FirestoreAlarmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== SHARED ALARM OPERATIONS ====================

  /// Create a new shared alarm in Firestore
  Future<String> createSharedAlarm(SharedAlarmModel alarm) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.sharedAlarmsCollection)
          .add(alarm.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create shared alarm: $e');
    }
  }

  /// Get a shared alarm by ID
  Future<SharedAlarmModel?> getSharedAlarmById(String alarmId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.sharedAlarmsCollection)
          .doc(alarmId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return SharedAlarmModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get shared alarm: $e');
    }
  }

  /// Get a shared alarm by share code
  Future<SharedAlarmModel?> getSharedAlarmByShareCode(String shareCode) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.sharedAlarmsCollection)
          .where('shareCode', isEqualTo: shareCode.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return SharedAlarmModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to find shared alarm: $e');
    }
  }

  /// Get real-time stream of a shared alarm
  Stream<SharedAlarmModel?> getSharedAlarmStream(String alarmId) {
    return _firestore
        .collection(AppConstants.sharedAlarmsCollection)
        .doc(alarmId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return null;
          }
          return SharedAlarmModel.fromFirestore(doc);
        });
  }

  /// Get all shared alarms created by a specific user or participated by them
  /// For MVP, we'll fetch alarms created by the user and active alarms.
  Stream<List<SharedAlarmModel>> getUserSharedAlarms(String userId) {
    return _firestore
        .collection(AppConstants.sharedAlarmsCollection)
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SharedAlarmModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Update shared alarm status
  Future<void> updateSharedAlarmStatus(
    String alarmId,
    SharedAlarmStatus status,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.sharedAlarmsCollection)
          .doc(alarmId)
          .update({'status': status.name});
    } catch (e) {
      throw Exception('Failed to update shared alarm status: $e');
    }
  }

  /// Cancel a shared alarm
  Future<void> cancelSharedAlarm(String alarmId) async {
    await updateSharedAlarmStatus(alarmId, SharedAlarmStatus.cancelled);
  }

  // ==================== PARTICIPANT OPERATIONS ====================

  /// Join a shared alarm with transaction for participant limit
  Future<void> joinSharedAlarm(
    String alarmId,
    SharedAlarmParticipantModel participant,
  ) async {
    try {
      final alarmRef = _firestore
          .collection(AppConstants.sharedAlarmsCollection)
          .doc(alarmId);

      final participantRef = alarmRef
          .collection(AppConstants.participantsCollection)
          .doc(participant.userId);

      await _firestore.runTransaction((transaction) async {
        final alarmDoc = await transaction.get(alarmRef);

        if (!alarmDoc.exists) {
          throw Exception('Alarm does not exist.');
        }

        final alarm = SharedAlarmModel.fromFirestore(alarmDoc);

        if (alarm.status != SharedAlarmStatus.active) {
          throw Exception(
            'Cannot join this alarm. It is ${alarm.status.name}.',
          );
        }

        // Check time
        if (alarm.triggerTime.isBefore(DateTime.now().toUtc())) {
          throw Exception('Alarm has already triggered.');
        }

        if (alarm.maxParticipants != null) {
          // get current participant count using an aggregate query inside transaction if possible,
          // or just standard get if aggregate is not supported in transactions.
          final participantsSnapshot = await alarmRef
              .collection(AppConstants.participantsCollection)
              .get();
          final currentCount = participantsSnapshot.docs.length;

          if (currentCount >= alarm.maxParticipants!) {
            throw Exception('Participant limit reached for this alarm.');
          }
        }

        transaction.set(participantRef, participant.toFirestore());
      });
    } catch (e) {
      throw Exception('Failed to join shared alarm: $e');
    }
  }

  /// Leave a shared alarm
  Future<void> leaveSharedAlarm(String alarmId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.sharedAlarmsCollection)
          .doc(alarmId)
          .collection(AppConstants.participantsCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to leave shared alarm: $e');
    }
  }

  /// Get real-time stream of participants for a shared alarm
  Stream<List<SharedAlarmParticipantModel>> getSharedAlarmParticipantsStream(
    String alarmId,
  ) {
    return _firestore
        .collection(AppConstants.sharedAlarmsCollection)
        .doc(alarmId)
        .collection(AppConstants.participantsCollection)
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SharedAlarmParticipantModel.fromFirestore(doc))
              .toList();
        });
  }
}
