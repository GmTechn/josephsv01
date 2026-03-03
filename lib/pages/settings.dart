// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:josephs_vs_01/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:josephs_vs_01/management/notifications.dart';
import 'package:josephs_vs_01/management/database.dart';
import 'package:josephs_vs_01/pages/homepage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseManager _db = DatabaseManager();
  final NotificationServices _notifs = NotificationServices.instance;

  bool _notificationsEnabled = true;

  static const _privacyUrl =
      'https://www.gabriellemtech.com/joseph-s#privacypolicy';
  static const _termsUrl = 'https://www.gabriellemtech.com/joseph-s#termsofuse';

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
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

    if (!enabled) {
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

  void _showThemeSelector() {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            _themeTile("Dark Mode", "dark"),
            _themeTile("Pink", "pink"),
            _themeTile("Blue", "blue"),
            _themeTile("Purple", "purple"),
            _themeTile("Green", "green"),
            _themeTile("Red", "red"),
            // _themeTile("Orange", "orange"),
            _themeTile("Original", "original"),
          ],
        ),
      ),
    );
  }

  Widget _themeTile(String title, String key) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.pop(context);
        MyApp.of(context).changeTheme(key);
      },
    );
  }

  void _confirmDelete() {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "⚠️Delete Account",
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
        content: const Text(
          "Are you sure you want to delete your account? "
          "This action cannot be undone.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xff050c20)),
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
                MaterialPageRoute(builder: (_) => const HomePage()),
                (_) => false,
              );
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("About Joseph's", style: TextStyle(fontSize: 16)),
        content: const Text(
          "Joseph’s helps you create, organize, and schedule tasks with smart reminders.\n\n"
          "Designed for simplicity and productivity, the app keeps you focused and organized throughout your day.\n\n"
          "Developed by GMTECH.\n\n"
          "© 2026 GMTECH. All rights reserved.",
          style: TextStyle(fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "S E T T I N G S",
          style: TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _sectionTitle("NOTIFICATIONS"),
          const SizedBox(height: 12),
          _tile(
            title: "Enable Notifications",
            subtitle: "Task reminders & alerts",
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeThumbColor:
                  Theme.of(context).extension<AppThemeKey>()?.key == "original"
                  ? const Color(0xff050c20)
                  : scheme.primary,
              activeTrackColor:
                  (Theme.of(context).extension<AppThemeKey>()?.key == "original"
                          ? const Color(0xff050c20)
                          : scheme.primary)
                      .withOpacity(.3),
            ),
          ),

          const SizedBox(height: 30),
          _sectionTitle("ACCOUNT"),
          const SizedBox(height: 12),
          _tile(
            title: "Delete Account",
            subtitle: "Remove all local data",
            onTap: _confirmDelete,
            isDanger: true,
          ),

          const SizedBox(height: 30),
          _sectionTitle("THEMES"),
          const SizedBox(height: 12),
          _tile(
            title: "Pick Theme",
            subtitle: "Choose your preferred app theme",
            onTap: _showThemeSelector,
          ),

          const SizedBox(height: 30),
          _sectionTitle("ABOUT"),
          const SizedBox(height: 12),
          _tile(
            title: "About the App",
            subtitle: "Version 1.0.0",
            onTap: _showAboutDialog,
          ),
          _tile(title: "Privacy Policy", onTap: () => _openLink(_privacyUrl)),
          _tile(title: "Terms of Use", onTap: () => _openLink(_termsUrl)),

          SizedBox(height: 60),

          Center(
            child: Text(
              '©Joseph\'s 2026. All rights reserved.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _tile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDanger = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16, // 👈 FIXED HERE
              color: isDanger ? Colors.red : scheme.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
              : null,
          trailing: trailing,
          onTap: onTap,
        ),
        Divider(
          height: 1,
          thickness: 0.8,
          color: scheme.onSurface.withValues(alpha: 0.1),
        ),
      ],
    );
  }
}
