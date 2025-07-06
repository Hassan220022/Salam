import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/prayer_notification_service.dart';
import '../providers/preference_settings_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _prayerNotificationsEnabled = true;
  int _reminderMinutes = 10;
  bool _dailyAyahEnabled = true;
  int _dailyAyahHour = 8;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings =
          await PrayerNotificationService.getNotificationSettings();
      setState(() {
        _prayerNotificationsEnabled =
            settings['prayer_notifications_enabled'] ?? true;
        _reminderMinutes = settings['reminder_minutes'] ?? 10;
        _dailyAyahEnabled = settings['daily_ayah_enabled'] ?? true;
        _dailyAyahHour = settings['daily_ayah_hour'] ?? 8;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings() async {
    try {
      await PrayerNotificationService.updateNotificationSettings(
        prayerNotificationsEnabled: _prayerNotificationsEnabled,
        reminderMinutes: _reminderMinutes,
        dailyAyahEnabled: _dailyAyahEnabled,
        dailyAyahHour: _dailyAyahHour,
      );

      // Reschedule notifications with new settings
      if (_dailyAyahEnabled) {
        await PrayerNotificationService.scheduleDailyAyahNotification();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notification Settings',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prayer notifications section
          _buildSectionHeader('Prayer Notifications'),
          const SizedBox(height: 16),
          _buildPrayerNotificationSettings(),
          const SizedBox(height: 32),

          // Daily Ayah section
          _buildSectionHeader('Daily Ayah'),
          const SizedBox(height: 16),
          _buildDailyAyahSettings(),
          const SizedBox(height: 32),

          // Notification info
          _buildNotificationInfo(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget _buildPrayerNotificationSettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Enable/disable prayer notifications
            Row(
              children: [
                Icon(
                  Icons.mosque,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prayer Time Reminders',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Get notified before each prayer time',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _prayerNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _prayerNotificationsEnabled = value;
                    });
                  },
                ),
              ],
            ),

            if (_prayerNotificationsEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Reminder time selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reminder Time:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: _reminderMinutes,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _reminderMinutes = value;
                          });
                        }
                      },
                      items: [5, 10, 15, 20, 30]
                          .map((minutes) => DropdownMenuItem(
                                value: minutes,
                                child: Text('$minutes minutes before', overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAyahSettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Enable/disable daily ayah
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Ayah Notification',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Receive inspiration from the Quran daily',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _dailyAyahEnabled,
                  onChanged: (value) {
                    setState(() {
                      _dailyAyahEnabled = value;
                    });
                  },
                ),
              ],
            ),

            if (_dailyAyahEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Daily ayah time selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Time:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: _dailyAyahHour,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _dailyAyahHour = value;
                          });
                        }
                      },
                      items: List.generate(24, (index) => index)
                          .map((hour) => DropdownMenuItem(
                                value: hour,
                                child:
                                    Text('${hour.toString().padLeft(2, '0')}:00'),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationInfo() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.secondaryContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Notification Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Prayer notifications require location permission\n'
              '• Notifications work even when the app is closed\n'
              '• You can customize notification sounds in your device settings\n'
              '• Daily Ayah includes beautiful verses with translations',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSecondaryContainer.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
