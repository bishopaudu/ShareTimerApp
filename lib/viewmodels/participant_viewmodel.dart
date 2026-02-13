import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/participant_model.dart';
import '../models/user_profile_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';

/// ViewModel for Participant operations
///
/// This ViewModel manages participant-related business logic including
/// joining timers, presence updates, and real-time participant lists.
class ParticipantViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  // State variables
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  UserProfileModel? _userProfile;
  Timer? _presenceTimer;

  /// Constructor
  ParticipantViewModel() {
    // Initialization is now done via initialize() method
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  UserProfileModel? get userProfile => _userProfile;

  /// Initialize the ViewModel
  /// Loads user ID and profile from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');

    if (_currentUserId == null) {
      _currentUserId = _uuid.v4();
      await prefs.setString('user_id', _currentUserId!);
    }

    await _loadProfile();
  }

  /// Get the current user ID, creating one if it doesn't exist (fallback)
  String getUserId() {
    if (_currentUserId == null) {
      // This case should ideally not happen if initialize() is called
      // but we handle it just in case
      _currentUserId = _uuid.v4();

      // We also try to save it asynchronously to persist it
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('user_id', _currentUserId!);
      });
    }
    return _currentUserId!;
  }

  /// Add current user as a participant to a timer
  ///
  /// This should be called when a user views a timer.
  /// It also starts a periodic presence update.
  Future<bool> joinTimer({required String timerId, String? displayName}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = getUserId();
      final now = DateTime.now().toUtc();

      final participant = ParticipantModel(
        userId: userId,
        displayName:
            displayName ?? _userProfile?.displayName ?? _generateDisplayName(),
        emoji: _userProfile?.emoji ?? '👋',
        joinedAt: now,
        lastSeen: now,
        timerId: timerId,
      );

      await _firebaseService.addParticipant(timerId, participant);

      // Start presence updates
      _startPresenceUpdates(timerId, userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to join timer: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove current user from a timer
  ///
  /// This should be called when a user leaves a timer view.
  /// It also stops the presence update timer.
  Future<void> leaveTimer(String timerId) async {
    try {
      final userId = getUserId();
      await _firebaseService.removeParticipant(timerId, userId);

      // Stop presence updates
      _stopPresenceUpdates();
    } catch (e) {
      _error = 'Failed to leave timer: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Get a stream of participants for a timer
  ///
  /// This provides real-time updates of all active participants.
  Stream<List<ParticipantModel>> getParticipantsStream(String timerId) {
    return _firebaseService.getParticipantsStream(timerId);
  }

  /// Start periodic presence updates
  ///
  /// Updates the user's lastSeen timestamp every 30 seconds
  /// to indicate they're still viewing the timer.
  void _startPresenceUpdates(String timerId, String userId) {
    // Cancel any existing timer
    _presenceTimer?.cancel();

    // Update presence every 30 seconds
    _presenceTimer = Timer.periodic(
      Duration(seconds: AppConstants.presenceUpdateInterval),
      (timer) async {
        try {
          await _firebaseService.updateParticipantPresence(timerId, userId);
        } catch (e) {
          print('Failed to update presence: $e');
        }
      },
    );
  }

  /// Stop presence updates
  void _stopPresenceUpdates() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
  }

  /// Remove inactive participants from a timer
  ///
  /// This is a cleanup utility that can be called periodically.
  Future<void> cleanupInactiveParticipants(String timerId) async {
    try {
      await _firebaseService.removeInactiveParticipants(timerId);
    } catch (e) {
      print('Failed to cleanup inactive participants: $e');
    }
  }

  /// Generate a random display name for anonymous users
  String _generateDisplayName() {
    final adjectives = [
      'Happy',
      'Cheerful',
      'Bright',
      'Swift',
      'Clever',
      'Brave',
      'Calm',
      'Bold',
      'Wise',
      'Kind',
    ];
    final nouns = [
      'Panda',
      'Tiger',
      'Eagle',
      'Dolphin',
      'Fox',
      'Wolf',
      'Bear',
      'Owl',
      'Lion',
      'Hawk',
    ];

    final random = DateTime.now().millisecondsSinceEpoch;
    final adjective = adjectives[random % adjectives.length];
    final noun = nouns[(random ~/ 10) % nouns.length];

    return '$adjective $noun';
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load user profile from SharedPreferences
  Future<void> _loadProfile() async {
    if (_currentUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile_$_currentUserId');

    if (profileJson != null) {
      _userProfile = UserProfileModel.fromJson(profileJson);
    } else {
      // Create a default profile
      _userProfile = UserProfileModel(
        id: _currentUserId!,
        displayName: _generateDisplayName(),
        emoji: '👋',
      );
      await _saveProfile();
    }
    notifyListeners();
  }

  /// Save user profile to SharedPreferences
  Future<void> _saveProfile() async {
    if (_userProfile == null || _currentUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'user_profile_$_currentUserId',
      _userProfile!.toJson(),
    );
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? emoji,
    bool? enableSound,
    bool? enableVibration,
  }) async {
    if (_userProfile == null) return;

    _userProfile = _userProfile!.copyWith(
      displayName: displayName,
      emoji: emoji,
      enableSound: enableSound,
      enableVibration: enableVibration,
    );

    await _saveProfile();
    print('Profile updated: ${_userProfile!.toJson()}'); // Debug log
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPresenceUpdates();
    super.dispose();
  }
}
