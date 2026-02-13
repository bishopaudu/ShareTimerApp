import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an alarm within a timer
///
/// Alarms trigger local notifications at specific points during
/// the countdown. They are stored in Firestore for synchronization
/// but notifications are handled locally on each device.
class AlarmModel {
  /// Unique identifier for the alarm
  final String id;

  /// ID of the parent timer
  final String timerId;

  /// Title/description of the alarm
  final String title;

  /// Trigger time in seconds from the timer start
  /// For example, 300 means the alarm triggers 5 minutes into the countdown
  final int triggerSeconds;

  /// Local notification ID (used for scheduling and canceling)
  /// This is device-specific and not synced
  final int notificationId;

  /// Timestamp when the alarm was created
  final DateTime createdAt;

  /// ID of the user who created the alarm
  final String createdBy;

  AlarmModel({
    required this.id,
    required this.timerId,
    required this.title,
    required this.triggerSeconds,
    required this.notificationId,
    required this.createdAt,
    required this.createdBy,
  });

  /// Create an AlarmModel from Firestore document snapshot
  factory AlarmModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AlarmModel(
      id: doc.id,
      timerId: data['timerId'] ?? '',
      title: data['title'] ?? '',
      triggerSeconds: data['triggerSeconds'] ?? 0,
      notificationId: data['notificationId'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  /// Convert AlarmModel to Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'timerId': timerId,
      'title': title,
      'triggerSeconds': triggerSeconds,
      'notificationId': notificationId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  /// Create a copy of this alarm with updated fields
  AlarmModel copyWith({
    String? id,
    String? timerId,
    String? title,
    int? triggerSeconds,
    int? notificationId,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      timerId: timerId ?? this.timerId,
      title: title ?? this.title,
      triggerSeconds: triggerSeconds ?? this.triggerSeconds,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Calculate the absolute DateTime when this alarm should trigger
  /// based on the timer's start time
  DateTime getTriggerTime(DateTime timerStartTime) {
    return timerStartTime.add(Duration(seconds: triggerSeconds));
  }

  /// Check if this alarm has already triggered
  bool hasTriggered(DateTime timerStartTime) {
    final triggerTime = getTriggerTime(timerStartTime);
    return DateTime.now().isAfter(triggerTime);
  }
}
