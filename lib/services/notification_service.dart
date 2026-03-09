import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/constants.dart';

/// Notification Service for local notifications
///
/// This service manages all local notifications for timers and alarms.
/// It handles initialization, permission requests, scheduling, and cancellation.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  /// Must be called before using any notification features
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data for scheduled notifications
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings - do NOT request permissions here.
    // Requesting permissions shows a system dialog which blocks the splash
    // screen initialization indefinitely. Call requestPermissions() separately
    // at an appropriate moment (e.g. after onboarding is complete).
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _initialized = true;
  }

  /// Create notification channels (Android only)
  Future<void> _createNotificationChannels() async {
    // Timer notifications channel
    const timerChannel = AndroidNotificationChannel(
      AppConstants.timerChannelId,
      AppConstants.timerChannelName,
      description: AppConstants.timerChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Alarm notifications channel
    const alarmChannel = AndroidNotificationChannel(
      AppConstants.alarmChannelId,
      AppConstants.alarmChannelName,
      description: AppConstants.alarmChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(timerChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(alarmChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific timer
    // For MVP, we'll just print the payload
    print('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  /// Returns true if granted, false otherwise
  Future<bool> requestPermissions() async {
    // iOS permissions
    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android 13+ permissions
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      final granted = await androidImplementation
          .requestNotificationsPermission();
      return granted ?? true; // Default to true for older Android versions
    }

    return true;
  }

  /// Schedule a timer end notification
  Future<void> scheduleTimerEndNotification({
    required int notificationId,
    required String timerTitle,
    required DateTime endTime,
    required String timerId,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.from(endTime, tz.local);

      // Don't schedule if the time is in the past
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        AppConstants.timerChannelId,
        AppConstants.timerChannelName,
        channelDescription: AppConstants.timerChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await _notifications.zonedSchedule(
          id: notificationId,
          title: 'Timer Finished!',
          body: '"$timerTitle" has finished counting down.',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'timer_$timerId',
        );
      } catch (e) {
        print('Failed to schedule exact timer notification: $e');
        // Fallback to inexact if exact fails
        await _notifications.zonedSchedule(
          id: notificationId,
          title: 'Timer Finished!',
          body: '"$timerTitle" has finished counting down.',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'timer_$timerId',
        );
      }
    } catch (e) {
      print('Failed to schedule timer notification: $e');
    }
  }

  /// Schedule an alarm notification
  Future<void> scheduleAlarmNotification({
    required int notificationId,
    required String alarmTitle,
    required DateTime triggerTime,
    required String timerId,
    required String alarmId,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.from(triggerTime, tz.local);

      // Don't schedule if the time is in the past
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        AppConstants.alarmChannelId,
        AppConstants.alarmChannelName,
        channelDescription: AppConstants.alarmChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await _notifications.zonedSchedule(
          id: notificationId,
          title: 'Alarm: $alarmTitle',
          body: 'Your alarm has been triggered.',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'alarm_${timerId}_$alarmId',
        );
      } catch (e) {
        print('Failed to schedule exact alarm notification: $e');
        // Fallback to inexact
        await _notifications.zonedSchedule(
          id: notificationId,
          title: 'Alarm: $alarmTitle',
          body: 'Your alarm has been triggered.',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'alarm_${timerId}_$alarmId',
        );
      }
    } catch (e) {
      print('Failed to schedule alarm notification: $e');
    }
  }

  /// Schedule a generic UTC-based shared alarm notification
  Future<void> scheduleSharedAlarmNotification({
    required int notificationId,
    required String alarmTitle,
    required DateTime triggerTimeUtc,
    required String alarmId,
  }) async {
    try {
      // Ensure triggerTime is treated as Local by timezone logic effectively converting from UTC correctly.
      final scheduledDate = tz.TZDateTime.from(
        triggerTimeUtc.toLocal(),
        tz.local,
      );

      // Don't schedule if the time is in the past
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        AppConstants.alarmChannelId,
        AppConstants.alarmChannelName,
        channelDescription: AppConstants.alarmChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await _notifications.zonedSchedule(
          id: notificationId,
          title: 'Shared Alarm: $alarmTitle',
          body: 'Your shared alarm has been triggered!',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'shared_alarm_$alarmId',
        );
      } catch (e) {
        print('Failed to schedule exact shared alarm notification: $e');
        // Fallback to inexact
        await _notifications.zonedSchedule(
          id: notificationId,
          title: 'Shared Alarm: $alarmTitle',
          body: 'Your shared alarm has been triggered!',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'shared_alarm_$alarmId',
        );
      }
    } catch (e) {
      print('Failed to schedule shared alarm notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notifications.cancel(id: notificationId);
    } catch (e) {
      print('Failed to cancel notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Failed to cancel all notifications: $e');
    }
  }

  /// Show an immediate notification (for testing or immediate alerts)
  Future<void> showImmediateNotification({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        AppConstants.timerChannelId,
        AppConstants.timerChannelName,
        channelDescription: AppConstants.timerChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Failed to show notification: $e');
    }
  }
}
