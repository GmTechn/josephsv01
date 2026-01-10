// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:josephs_vs_01/management/notifications.dart';
import 'package:josephs_vs_01/management/database.dart';
import 'package:josephs_vs_01/models/users.dart';
import 'package:josephs_vs_01/pages/homepage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseManager _db = DatabaseManager();
  final NotificationServices _notifs = NotificationServices.instance;

  AppUser? _user;
  bool _notificationsEnabled = true;

  static const _privacyUrl =
      'https://sites.google.com/view/josephsprivacypolicy/privacy-policy';
  static const _termsUrl =
      'https://sites.google.com/view/josephsprivacypolicy/terms-of-use';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadNotificationSetting();
  }

  Future<void> _loadUser() async {
    final u = await _db.getLocalUser();
    if (!mounted) return;
    setState(() => _user = u);
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    if (enabled) {
      final status = await _notifs.debugPermissions();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(status)));
    } else {
      await _notifs.cancelAll();
    }

    await prefs.setBool('notifications_enabled', enabled);

    if (!mounted) return;
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("About Joseph's", style: TextStyle(fontSize: 16)),
        content: const Text(
          "Josephs helps you create, organize, and schedule tasks with smart reminders.\n"
          "Designed for simplicity and productivity, the app keeps you focused and organized throughout your day.\n"
          "Developed by GMTECH, Josephs helps turn your plans into action."
          "\n\n© 2025 GMTECH. All rights reserved.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xff050c20))),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          '⚠️ Delete Account',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
        content: const Text(
          'This will permanently delete all your local data.',
          style: TextStyle(fontSize: 12),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xff050c20), fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _db.resetDb();
              await _notifs.cancelAll();

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (_) => false,
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Color(0xff050c20)),
        title: const Text(
          'S E T T I N G S',
          style: TextStyle(color: Color(0xff050c20)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- NOTIFICATIONS ----------------
          const Text(
            'NOTIFICATIONS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xff050c20),
            ),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            value: _notificationsEnabled,
            activeThumbColor: const Color(0xff050c20),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Task reminders & alerts'),
            onChanged: _toggleNotifications,
          ),

          // ListTile(
          //   leading: const Icon(CupertinoIcons.bell),
          //   title: const Text('Send Test Notification (Now)'),
          //   onTap: _sendTestNow,
          // ),
          // ListTile(
          //   leading: const Icon(CupertinoIcons.timer),
          //   title: const Text('Send Test Notification (5 seconds)'),
          //   onTap: _sendTestIn5Seconds,
          // ),
          const Divider(height: 30),

          // ---------------- ACCOUNT ----------------
          const Text(
            'ACCOUNT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xff050c20),
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            title: const Text('Delete Account'),
            subtitle: const Text('Remove all local data'),
            onTap: _user != null ? _confirmDelete : null,
          ),

          const Divider(height: 30),

          // ---------------- ABOUT ----------------
          const Text(
            'ABOUT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xff050c20),
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(CupertinoIcons.info),
            title: const Text('About the App'),
            subtitle: const Text('Version 1.0.0'),
            onTap: _showAboutDialog,
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.shield),
            title: const Text('Privacy Policy'),
            onTap: () => _openLink(_privacyUrl),
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.doc_text),
            title: const Text('Terms of Use'),
            onTap: () => _openLink(_termsUrl),
          ),
        ],
      ),
    );
  }
}
