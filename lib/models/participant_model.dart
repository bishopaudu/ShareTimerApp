import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a participant viewing a timer
///
/// This model tracks users who are currently viewing a shared timer.
/// It includes presence detection to automatically remove inactive users.
class ParticipantModel {
  /// Unique identifier for the participant (device-generated UUID)
  final String userId;

  /// Display name for the participant
  /// Can be customized by the user or auto-generated
  final String displayName;

  /// Emoji avatar for the participant
  final String emoji;

  /// Timestamp when the participant joined the timer
  final DateTime joinedAt;

  /// Last seen timestamp for presence detection
  /// Updated periodically to indicate the user is still active
  final DateTime lastSeen;

  /// ID of the timer this participant is viewing
  final String timerId;

  ParticipantModel({
    required this.userId,
    required this.displayName,
    required this.emoji,
    required this.joinedAt,
    required this.lastSeen,
    required this.timerId,
  });

  /// Create a ParticipantModel from Firestore document snapshot
  factory ParticipantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ParticipantModel(
      userId: doc.id,
      displayName: data['displayName'] ?? 'Anonymous',
      emoji: data['emoji'] ?? '👋',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
      timerId: data['timerId'] ?? '',
    );
  }

  /// Convert ParticipantModel to Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'emoji': emoji,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'timerId': timerId,
    };
  }

  /// Create a copy of this participant with updated fields
  /// Useful for updating lastSeen timestamp
  ParticipantModel copyWith({
    String? userId,
    String? displayName,
    String? emoji,
    DateTime? joinedAt,
    DateTime? lastSeen,
    String? timerId,
  }) {
    return ParticipantModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      emoji: emoji ?? this.emoji,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      timerId: timerId ?? this.timerId,
    );
  }

  /// Check if this participant is still active
  /// A participant is considered inactive if not seen for 2+ minutes
  bool isActive() {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    return difference.inMinutes < 2;
  }
}
