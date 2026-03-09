import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a participant in a Shared Alarm Event
class SharedAlarmParticipantModel {
  final String userId;
  final String displayName;
  final String emoji;
  final DateTime joinedAt;

  SharedAlarmParticipantModel({
    required this.userId,
    required this.displayName,
    required this.emoji,
    required this.joinedAt,
  });

  /// Create a SharedAlarmParticipantModel from Firestore document snapshot
  factory SharedAlarmParticipantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SharedAlarmParticipantModel(
      userId: doc.id,
      displayName: data['displayName'] ?? 'Anonymous',
      emoji: data['emoji'] ?? '👋',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert SharedAlarmParticipantModel to Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'emoji': emoji,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}
