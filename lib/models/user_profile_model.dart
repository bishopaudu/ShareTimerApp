import 'dart:convert';

/// Model representing a user's local profile and preferences.
class UserProfileModel {
  final String id;
  final String displayName;
  final String emoji;
  final bool enableSound;
  final bool enableVibration;

  UserProfileModel({
    required this.id,
    required this.displayName,
    required this.emoji,
    this.enableSound = true,
    this.enableVibration = true,
  });

  /// Create a copy of this profile with some fields updated.
  UserProfileModel copyWith({
    String? displayName,
    String? emoji,
    bool? enableSound,
    bool? enableVibration,
  }) {
    return UserProfileModel(
      id: id,
      displayName: displayName ?? this.displayName,
      emoji: emoji ?? this.emoji,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
    );
  }

  /// Convert profile to Map for storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'emoji': emoji,
      'enableSound': enableSound,
      'enableVibration': enableVibration,
    };
  }

  /// Create a profile from a Map.
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '',
      emoji: map['emoji'] ?? '👋',
      enableSound: map['enableSound'] ?? true,
      enableVibration: map['enableVibration'] ?? true,
    );
  }

  /// Convert to JSON string.
  String toJson() => json.encode(toMap());

  /// Create from JSON string.
  factory UserProfileModel.fromJson(String source) =>
      UserProfileModel.fromMap(json.decode(source));
}
