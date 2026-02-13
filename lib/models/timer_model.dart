import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a countdown timer
///
/// This model follows MVVM architecture and represents the data structure
/// for a shared countdown timer. It includes all necessary fields for
/// real-time synchronization via Firebase Firestore.
class TimerModel {
  /// Unique identifier for the timer (UUID)
  final String id;

  /// User-friendly title for the timer
  final String title;

  /// Duration of the timer in seconds
  final int durationSeconds;

  /// Start time of the timer (UTC timestamp)
  /// This is crucial for handling clock skew across devices
  final DateTime startTime;

  /// End time of the timer (calculated from startTime + duration)
  final DateTime endTime;

  /// Current status of the timer
  final TimerStatus status;

  /// ID of the user who created the timer
  final String creatorId;

  /// 6-digit alphanumeric share code for easy joining
  final String shareCode;

  /// Timestamp when the timer was created
  final DateTime createdAt;

  TimerModel({
    required this.id,
    required this.title,
    required this.durationSeconds,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.creatorId,
    required this.shareCode,
    required this.createdAt,
  });

  /// Create a TimerModel from Firestore document snapshot
  /// Handles type conversion and null safety
  factory TimerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TimerModel(
      id: doc.id,
      title: data['title'] ?? '',
      durationSeconds: data['durationSeconds'] ?? 0,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: TimerStatus.values.firstWhere(
        (e) => e.toString() == 'TimerStatus.${data['status']}',
        orElse: () => TimerStatus.active,
      ),
      creatorId: data['creatorId'] ?? '',
      shareCode: data['shareCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert TimerModel to Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'durationSeconds': durationSeconds,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status.toString().split('.').last,
      'creatorId': creatorId,
      'shareCode': shareCode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy of this timer with updated fields
  TimerModel copyWith({
    String? id,
    String? title,
    int? durationSeconds,
    DateTime? startTime,
    DateTime? endTime,
    TimerStatus? status,
    String? creatorId,
    String? shareCode,
    DateTime? createdAt,
  }) {
    return TimerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      shareCode: shareCode ?? this.shareCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Enum representing the possible states of a timer
enum TimerStatus {
  /// Timer is actively counting down
  active,

  /// Timer has been paused (future enhancement)
  paused,

  /// Timer has finished counting down
  finished,
}
