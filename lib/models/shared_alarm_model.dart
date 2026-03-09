import 'package:cloud_firestore/cloud_firestore.dart';

enum SharedAlarmStatus { active, cancelled, triggered }

/// Model representing a Shared Alarm Event
class SharedAlarmModel {
  final String id;
  final String title;
  final String? description;
  final String creatorId; // User ID who created the alarm
  final DateTime triggerTime; // Stored as UTC Timestamp in Firestore
  final DateTime createdAt;
  final int? maxParticipants;
  final SharedAlarmStatus status;
  final String shareCode;

  SharedAlarmModel({
    required this.id,
    required this.title,
    this.description,
    required this.creatorId,
    required this.triggerTime,
    required this.createdAt,
    this.maxParticipants,
    required this.status,
    required this.shareCode,
  });

  /// Create a SharedAlarmModel from Firestore document snapshot
  factory SharedAlarmModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SharedAlarmModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      creatorId: data['creatorId'] ?? '',
      triggerTime: (data['triggerTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      maxParticipants: data['maxParticipants'],
      status: _parseStatus(data['status']),
      shareCode: data['shareCode'] ?? '',
    );
  }

  /// Convert SharedAlarmModel to Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'triggerTime': Timestamp.fromDate(
        triggerTime,
      ), // Ensure it's stored in UTC
      'createdAt': Timestamp.fromDate(createdAt),
      'maxParticipants': maxParticipants,
      'status': status.name,
      'shareCode': shareCode,
    };
  }

  static SharedAlarmStatus _parseStatus(String? statusString) {
    switch (statusString) {
      case 'cancelled':
        return SharedAlarmStatus.cancelled;
      case 'triggered':
        return SharedAlarmStatus.triggered;
      case 'active':
      default:
        return SharedAlarmStatus.active;
    }
  }

  SharedAlarmModel copyWith({
    String? id,
    String? title,
    String? description,
    String? creatorId,
    DateTime? triggerTime,
    DateTime? createdAt,
    int? maxParticipants,
    SharedAlarmStatus? status,
    String? shareCode,
  }) {
    return SharedAlarmModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      triggerTime: triggerTime ?? this.triggerTime,
      createdAt: createdAt ?? this.createdAt,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      status: status ?? this.status,
      shareCode: shareCode ?? this.shareCode,
    );
  }
}
