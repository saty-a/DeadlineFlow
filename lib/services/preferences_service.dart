import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  static PreferencesService? _instance;
  SharedPreferences? _prefs;

  PreferencesService._();

  static PreferencesService get instance {
    _instance ??= PreferencesService._();
    return _instance!;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Onboarding
  bool get hasSeenOnboarding {
    return _prefs?.getBool(_hasSeenOnboardingKey) ?? false;
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs?.setBool(_hasSeenOnboardingKey, value);
  }

  // Notifications
  bool get notificationsEnabled {
    return _prefs?.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_notificationsEnabledKey, value);
  }
}
