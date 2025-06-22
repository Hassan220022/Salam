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
    final isDarkTheme =
        Provider.of<PreferenceSettingsProvider>(context).isDarkTheme;

    return Scaffold(
      backgroundColor: isDarkTheme ? const Color(0xFF091945) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notification Settings',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkTheme ? Colors.white : const Color(0xFF091945),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.save,
              color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            ),
            onPressed: _updateSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
            )
          : _buildBody(isDarkTheme),
    );
  }

  Widget _buildBody(bool isDarkTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prayer notifications section
          _buildSectionHeader('Prayer Notifications', isDarkTheme),
          const SizedBox(height: 16),
          _buildPrayerNotificationSettings(isDarkTheme),
          const SizedBox(height: 32),

          // Daily Ayah section
          _buildSectionHeader('Daily Ayah', isDarkTheme),
          const SizedBox(height: 16),
          _buildDailyAyahSettings(isDarkTheme),
          const SizedBox(height: 32),

          // Notification info
          _buildNotificationInfo(isDarkTheme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkTheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDarkTheme ? Colors.white : const Color(0xFF091945),
      ),
    );
  }

  Widget _buildPrayerNotificationSettings(bool isDarkTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkTheme
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Enable/disable prayer notifications
          Row(
            children: [
              Icon(
                Icons.mosque,
                color: isDarkTheme ? Colors.white : const Color(0xFF091945),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prayer Time Reminders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkTheme
                            ? Colors.white
                            : const Color(0xFF091945),
                      ),
                    ),
                    Text(
                      'Get notified before each prayer time',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDarkTheme ? Colors.white70 : Colors.grey.shade600,
                      ),
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
                activeColor: const Color(0xFF667eea),
              ),
            ],
          ),

          if (_prayerNotificationsEnabled) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Reminder time selector
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: isDarkTheme ? Colors.white70 : Colors.grey.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reminder Time:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkTheme ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: _reminderMinutes,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _reminderMinutes = value;
                      });
                    }
                  },
                  dropdownColor:
                      isDarkTheme ? const Color(0xFF091945) : Colors.white,
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : const Color(0xFF091945),
                  ),
                  items: [5, 10, 15, 20, 30]
                      .map((minutes) => DropdownMenuItem(
                            value: minutes,
                            child: Text('$minutes minutes before'),
                          ))
                      .toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyAyahSettings(bool isDarkTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkTheme
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Enable/disable daily ayah
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: isDarkTheme ? Colors.white : const Color(0xFF091945),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Ayah Notification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkTheme
                            ? Colors.white
                            : const Color(0xFF091945),
                      ),
                    ),
                    Text(
                      'Receive inspiration from the Quran daily',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDarkTheme ? Colors.white70 : Colors.grey.shade600,
                      ),
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
                activeColor: const Color(0xFF667eea),
              ),
            ],
          ),

          if (_dailyAyahEnabled) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Daily ayah time selector
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: isDarkTheme ? Colors.white70 : Colors.grey.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Time:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkTheme ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: _dailyAyahHour,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _dailyAyahHour = value;
                      });
                    }
                  },
                  dropdownColor:
                      isDarkTheme ? const Color(0xFF091945) : Colors.white,
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : const Color(0xFF091945),
                  ),
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
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationInfo(bool isDarkTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Notification Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
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
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
