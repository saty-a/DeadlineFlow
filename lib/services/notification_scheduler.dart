import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Responsible solely for scheduling and cancelling individual notifications.
class NotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin;

  const NotificationScheduler(this._plugin);

  static const _channelId = 'deadline_reminders';
  static const _channelName = 'Deadline Reminders';

  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: 'Notifications for upcoming task deadlines',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
  );

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const _details = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  /// Creates the Android notification channel. Must be called once during init.
  Future<void> createChannel() async {
    if (!Platform.isAndroid) return;
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifications for upcoming task deadlines',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledAt, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    // Try exact alarm first (USE_EXACT_ALARM in manifest = auto-granted API 33+).
    // Falls back to inexact if exact is unavailable.
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('NotificationScheduler: scheduled exact id=$id at $tzTime "$title"');
    } catch (e) {
      debugPrint('NotificationScheduler: exact failed id=$id ($e) — falling back to inexact');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzTime,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('NotificationScheduler: scheduled inexact id=$id at $tzTime');
      } catch (e2) {
        debugPrint('NotificationScheduler: FAILED id=$id – $e2');
      }
    }
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();
}
