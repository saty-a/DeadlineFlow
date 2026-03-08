 import 'package:shared_preferences/shared_preferences.dart';

enum ReminderInterval {
  twoHours,
  oneHour,
  tenMinutes,
  atDeadline,
  missed,
}

extension ReminderIntervalX on ReminderInterval {
  String get label {
    switch (this) {
      case ReminderInterval.twoHours:
        return '2 hours before';
      case ReminderInterval.oneHour:
        return '1 hour before';
      case ReminderInterval.tenMinutes:
        return '10 minutes before';
      case ReminderInterval.atDeadline:
        return 'At deadline';
      case ReminderInterval.missed:
        return 'If overdue';
    }
  }

  /// How far before the deadline to fire. Null means after (missed).
  Duration? get offsetBefore {
    switch (this) {
      case ReminderInterval.twoHours:
        return const Duration(hours: 2);
      case ReminderInterval.oneHour:
        return const Duration(hours: 1);
      case ReminderInterval.tenMinutes:
        return const Duration(minutes: 10);
      case ReminderInterval.atDeadline:
        return Duration.zero;
      case ReminderInterval.missed:
        return null;
    }
  }
}

/// Responsible solely for persisting the user's chosen reminder intervals.
class NotificationPreferencesService {
  static const _key = 'notification_reminder_intervals';

  static const Set<ReminderInterval> _defaults = {
    ReminderInterval.oneHour,
    ReminderInterval.atDeadline,
    ReminderInterval.missed,
  };

  static NotificationPreferencesService? _instance;
  SharedPreferences? _prefs;

  NotificationPreferencesService._();

  static NotificationPreferencesService get instance {
    _instance ??= NotificationPreferencesService._();
    return _instance!;
  }

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  Set<ReminderInterval> get enabledIntervals {
    final stored = _prefs?.getStringList(_key);
    if (stored == null) return Set.of(_defaults);
    return stored
        .map((s) => ReminderInterval.values.firstWhere(
              (e) => e.name == s,
              orElse: () => ReminderInterval.oneHour,
            ))
        .toSet();
  }

  Future<void> setEnabledIntervals(Set<ReminderInterval> intervals) async {
    await _prefs?.setStringList(
      _key,
      intervals.map((e) => e.name).toList(),
    );
  }

  Future<void> toggleInterval(ReminderInterval interval) async {
    final current = enabledIntervals;
    if (current.contains(interval)) {
      current.remove(interval);
    } else {
      current.add(interval);
    }
    await setEnabledIntervals(current);
  }
}
