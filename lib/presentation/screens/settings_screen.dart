import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../logic/theme_provider.dart';
import 'webview_screen.dart';
import 'widget_gallery_screen.dart';
import '../../services/notification_service.dart';
import '../../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Loading...';

  static const String _privacyPolicyUrl = 'https://sites.google.com/view/deadlineflow/home';
  static const String _playStorePackageName = 'com.sun2.chessclock';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version+packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Unknown';
      });
    }
  }

  Future<void> _openPrivacyPolicy() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebViewScreen(
          title: 'Privacy Policy',
          url: _privacyPolicyUrl,
        ),
      ),
    );
  }

  Future<void> _rateApp() async {
    final playStoreUrl = Uri.parse(
      'https://play.google.com/store/apps/details?id=$_playStorePackageName',
    );

    try {
      if (await canLaunchUrl(playStoreUrl)) {
        await launchUrl(
          playStoreUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          _showErrorSnackBar('Unable to open Play Store');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error opening Play Store: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.titleLarge?.color),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Appearance Section
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      _buildSettingsTile(
                        icon: Icons.brightness_6_outlined,
                        title: 'Theme',
                        subtitle: _getThemeName(themeProvider.themeModeToString()),
                        onTap: () => _showThemeDialog(themeProvider),
                      ),
                      const Divider(height: 1),
                      _buildSettingsTile(
                        icon: Icons.palette_outlined,
                        title: 'Primary Color',
                        subtitle: _getColorName(themeProvider.primaryColor),
                        trailing: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 2,
                            ),
                          ),
                        ),
                        onTap: () => _showColorDialog(themeProvider),
                        showDivider: false,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Notifications Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  _buildNotificationToggle(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Widgets Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Widgets',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.widgets_outlined,
                    title: 'Widget Gallery',
                    subtitle: 'Add widget to home screen',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WidgetGalleryScreen(),
                        ),
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'About',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: _openPrivacyPolicy,
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.star_outline,
                    title: 'Rate App',
                    onTap: _rateApp,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'App Version: $_appVersion',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getThemeName(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }

  String _getColorName(Color color) {
    final hexString = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    final colorInfo = ThemeProvider.colorOptions[hexString];
    return colorInfo?['name'] ?? 'Custom';
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose your preferred theme',
              style: TextStyle(fontSize: 14, color: Color(0xFF8F9BB3)),
            ),
            const SizedBox(height: 16),
            _buildThemeOption('Light', 'light', themeProvider),
            _buildThemeOption('Dark', 'dark', themeProvider),
            _buildThemeOption('System', 'system', themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String label, String value, ThemeProvider themeProvider) {
    final isSelected = themeProvider.themeModeToString() == value;
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: themeProvider.themeModeToString(),
      onChanged: (newValue) {
        if (newValue != null) {
          themeProvider.setThemeMode(newValue);
          Navigator.pop(context);
        }
      },
      activeColor: Theme.of(context).primaryColor,
    );
  }

  void _showColorDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choose Primary Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ThemeProvider.colorOptions.entries.map((entry) {
              final hexString = entry.key;
              final colorInfo = entry.value;
              final color = colorInfo['color'] as Color;
              final name = colorInfo['name'] as String;
              final description = colorInfo['description'] as String;

              return _buildColorOption(
                hexString,
                color,
                name,
                description,
                themeProvider,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(
    String hexString,
    Color color,
    String name,
    String description,
    ThemeProvider themeProvider,
  ) {
    final currentColorHex = '#${themeProvider.primaryColor.value.toRadixString(16).substring(2).toUpperCase()}';
    final isSelected = currentColorHex == hexString;

    return InkWell(
      onTap: () {
        themeProvider.setPrimaryColor(hexString);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return StatefulBuilder(
      builder: (context, setState) {
        final isEnabled = PreferencesService.instance.notificationsEnabled;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deadline Reminders',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Get notified before deadlines',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Request permission when enabling
                    final granted = await NotificationService.instance.requestPermission();
                    if (granted) {
                      await PreferencesService.instance.setNotificationsEnabled(true);
                      setState(() {});
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Notification permission denied'),
                            backgroundColor: Colors.red.shade400,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  } else {
                    await PreferencesService.instance.setNotificationsEnabled(false);
                    await NotificationService.instance.cancelAllNotifications();
                    setState(() {});
                  }
                },
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        );
      },
    );
  }
}
