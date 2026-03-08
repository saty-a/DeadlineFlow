import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../data/models/task.dart';
import 'notification_scheduler.dart';
import 'notification_preferences_service.dart';
import 'preferences_service.dart';

/// Orchestrates scheduling reminders for tasks based on the user's
/// chosen [ReminderInterval] preferences.
class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  late final NotificationScheduler _scheduler;
  bool _isInitialized = false;

  NotificationService._();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    _scheduler = NotificationScheduler(_plugin);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _scheduler.createChannel();
    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {}

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final plugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await plugin?.requestNotificationsPermission() ?? false;
      if (!granted) return false;

      // Request battery optimization exclusion so notifications fire reliably
      // in Doze mode and on OEM devices with aggressive battery management.
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (batteryStatus.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
      return true;
    } else if (Platform.isIOS) {
      final plugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await plugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      final plugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await plugin?.areNotificationsEnabled() ?? false;
    }
    return _isInitialized;
  }

  /// Schedules all enabled reminder intervals for [task].
  /// Cancels any previously scheduled notifications for the same task first.
  Future<void> scheduleTaskReminders(Task task) async {
    if (!PreferencesService.instance.notificationsEnabled) return;
    if (task.isCompleted) return;

    await cancelTaskNotifications(task.id);

    final now = DateTime.now();
    final enabledIntervals =
        NotificationPreferencesService.instance.enabledIntervals;

    for (final interval in ReminderInterval.values) {
      if (!enabledIntervals.contains(interval)) continue;

      if (interval == ReminderInterval.missed) {
        // Fire 5 minutes after the deadline if the user hasn't completed the task
        final missedAt = task.deadline.add(const Duration(minutes: 5));
        if (missedAt.isAfter(now)) {
          await _scheduler.schedule(
            id: _notificationId(task.id, interval),
            title: 'Missed Deadline! ⚠️',
            body: '"${task.name}" was due ${_timeAgoLabel(task.deadline)}.',
            scheduledAt: missedAt,
          );
        }
      } else {
        final offset = interval.offsetBefore!;
        final scheduledAt = task.deadline.subtract(offset);
        if (scheduledAt.isAfter(now)) {
          await _scheduler.schedule(
            id: _notificationId(task.id, interval),
            title: _titleFor(interval),
            body: '"${task.name}" ${_bodyFor(interval)}',
            scheduledAt: scheduledAt,
          );
        }
      }
    }
  }

  /// Cancels all reminder notifications for a specific task.
  Future<void> cancelTaskNotifications(String taskId) async {
    for (final interval in ReminderInterval.values) {
      await _scheduler.cancel(_notificationId(taskId, interval));
    }
  }

  Future<void> cancelAllNotifications() => _scheduler.cancelAll();

  int _notificationId(String taskId, ReminderInterval interval) {
    return '${taskId}_${interval.name}'.hashCode.abs() % 2147483647;
  }

  String _titleFor(ReminderInterval interval) {
    switch (interval) {
      case ReminderInterval.twoHours:
        return 'Deadline in 2 Hours ⏰';
      case ReminderInterval.oneHour:
        return 'Deadline in 1 Hour ⏰';
      case ReminderInterval.tenMinutes:
        return 'Deadline in 10 Minutes ⚡';
      case ReminderInterval.atDeadline:
        return 'Deadline Reached! \u{1F6A8}';
      case ReminderInterval.missed:
        return 'Missed Deadline! ⚠️';
    }
  }

  String _bodyFor(ReminderInterval interval) {
    switch (interval) {
      case ReminderInterval.twoHours:
        return 'is due in 2 hours!';
      case ReminderInterval.oneHour:
        return 'is due in 1 hour!';
      case ReminderInterval.tenMinutes:
        return 'is due in 10 minutes!';
      case ReminderInterval.atDeadline:
        return 'deadline is now!';
      case ReminderInterval.missed:
        return '';
    }
  }

  String _timeAgoLabel(DateTime deadline) {
    final diff = DateTime.now().difference(deadline);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours}h ago';
  }
}
