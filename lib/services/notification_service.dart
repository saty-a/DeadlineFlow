import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../data/models/task.dart';
import 'preferences_service.dart';

class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to specific task
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return false;
  }

  Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.areNotificationsEnabled() ?? false;
      }
    }
    // For iOS, we assume permission is granted if we've initialized
    return _isInitialized;
  }

  Future<void> scheduleTaskReminder(Task task) async {
    if (!PreferencesService.instance.notificationsEnabled) return;
    if (task.isCompleted) return;

    final now = DateTime.now();
    if (task.deadline.isBefore(now)) return;

    // Cancel any existing notifications for this task
    await cancelTaskNotifications(task.id);

    // Schedule notification 1 hour before deadline
    final oneHourBefore = task.deadline.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _scheduleNotification(
        id: _getNotificationId(task.id, 'reminder'),
        title: 'Deadline Reminder ⏰',
        body: '"${task.name}" is due in 1 hour!',
        scheduledDate: oneHourBefore,
      );
    }

    // Schedule notification at deadline
    await _scheduleNotification(
      id: _getNotificationId(task.id, 'deadline'),
      title: 'Deadline Reached! 🚨',
      body: '"${task.name}" deadline is now!',
      scheduledDate: task.deadline,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'deadline_reminders',
      'Deadline Reminders',
      channelDescription: 'Notifications for upcoming task deadlines',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    await _notifications.cancel(_getNotificationId(taskId, 'reminder'));
    await _notifications.cancel(_getNotificationId(taskId, 'deadline'));
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  int _getNotificationId(String taskId, String type) {
    // Generate unique notification ID from task ID and type
    final combined = '$taskId-$type';
    return combined.hashCode.abs() % 2147483647;
  }
}
