import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'account_profile_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _reminderAlertsEnabled = true;
  bool _taskNotificationsEnabled = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not open URL: $url')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open URL: $url')),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    // placeholder removed - navigation now handled in AccountProfileView
  }
  

  Future<void> _showLicensesDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legal Notices'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'MyReminder © 2024\n\n'
                'This app is built with:\n'
                '- Flutter\n'
                '- Provider for state management\n'
                '- Supabase for backend\n'
                '- SQLite for local storage\n\n'
                'All rights reserved.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Account & Profile Section
          _buildSectionHeader('Account & Profile'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account & Profile'),
            subtitle: const Text('Manage your personal information'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AccountProfileView(),
                ),
              );
            },
          ),
          const Divider(),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Reminder Alerts'),
            subtitle: const Text('Get notified for reminders'),
            value: _reminderAlertsEnabled,
            onChanged: (value) {
              setState(() => _reminderAlertsEnabled = value);
              // TODO: Persist preference
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_today),
            title: const Text('Task Due Notifications'),
            subtitle: const Text('Get notified when tasks are due'),
            value: _taskNotificationsEnabled,
            onChanged: (value) {
              setState(() => _taskNotificationsEnabled = value);
              // TODO: Persist preference
            },
          ),
          const Divider(),

          // Privacy & Data Section
          _buildSectionHeader('Privacy & Data'),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy & Data'),
            subtitle: const Text('Review privacy policy and terms'),
            onTap: () {
              // TODO: Navigate to privacy details screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('Privacy Policy'),
            onTap: () {
              _launchURL('https://example.com/privacy');
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            onTap: () {
              _launchURL('https://example.com/terms');
            },
          ),
          const Divider(),

          // About Section
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About This App'),
            subtitle: const Text('App version and legal notices'),
            onTap: () {
              // TODO: Navigate to about details screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.mobile_friendly),
            title: const Text('App Version'),
            subtitle: Text(_appVersion.isNotEmpty ? _appVersion : 'Loading...'),
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('Legal Notices'),
            onTap: _showLicensesDialog,
          ),
          const SizedBox(height: 32),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}
