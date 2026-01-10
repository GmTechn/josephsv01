// ignore_for_file: use_build_context_synchronously, deprecated_member_use, depend_on_referenced_packages

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:josephs_vs_01/pages/settings.dart';
import 'package:path_provider/path_provider.dart';

import 'package:josephs_vs_01/components/mynavbar.dart';
import 'package:josephs_vs_01/components/stattile.dart';
import 'package:josephs_vs_01/management/database.dart';
import 'package:josephs_vs_01/models/tasks.dart';
import 'package:josephs_vs_01/models/users.dart';
import 'package:josephs_vs_01/pages/schedule.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  //database instance
  final DatabaseManager _db = DatabaseManager();
  //current user
  AppUser? _currentUser;

  final ImagePicker _picker = ImagePicker();
  bool _picking = false;

  int totalTasks = 0;
  int completedToday = 0;
  int overdueCount = 0;

  List<_DashTaskItem> todayTasks = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadDashboardTasks();
  }

  Future<void> _refreshAll() async {
    await _loadUser();
    await _loadDashboardTasks();
  }

  // ----------------------------
  // USER
  // ----------------------------
  Future<void> _loadUser() async {
    final u = await _db.getLocalUser();
    if (!mounted) return;
    setState(() => _currentUser = u);
  }

  // ----------------------------
  // TASKS for dashboard
  // ----------------------------
  Future<void> _loadDashboardTasks() async {
    final all = await _db.getTasks();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int total = all.length;
    int completed = 0;
    int overdue = 0;

    final List<_DashTaskItem> computed = [];

    for (final t in all) {
      final taskDay = DateTime(t.date.year, t.date.month, t.date.day);
      final isDone = (t.status).toLowerCase() == 'done';

      // completed today count
      if (isDone && taskDay == today) {
        completed++;
        continue;
      }

      // show ONLY today's tasks in list
      if (taskDay != today) continue;

      final res = _computeTodayStatusAndColor(t, now, today);
      if (res.status == 'overdue') overdue++;

      computed.add(
        _DashTaskItem(task: t, status: res.status, color: res.color),
      );
    }

    // sort by start time if exists
    int timeKey(String? st, String status) {
      if (status == 'no_time') return 24 * 60 + 2; // always last
      if (st == null || st.trim().isEmpty) return 24 * 60 + 2;
      try {
        final dt = DateFormat.jm().parse(st);
        return dt.hour * 60 + dt.minute;
      } catch (_) {
        return 24 * 60 + 2;
      }
    }

    computed.sort(
      (a, b) => timeKey(
        a.task.startTime,
        a.status,
      ).compareTo(timeKey(b.task.startTime, b.status)),
    );

    if (!mounted) return;
    setState(() {
      totalTasks = total;
      completedToday = completed;
      overdueCount = overdue;
      todayTasks = computed;
    });
  }

  // ----------------------------
  // GREETING
  // ----------------------------
  String _timeGreetingText() {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }

  IconData _timeGreetingIcon() {
    final h = DateTime.now().hour;
    if (h < 12) return CupertinoIcons.sun_max_fill;
    if (h < 17) return CupertinoIcons.cloud_sun_fill;
    return CupertinoIcons.moon_fill;
  }

  // ----------------------------
  // NAV
  // ----------------------------
  void _openSchedulePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SchedulePage()),
    ).then((_) => _loadDashboardTasks());
  }

  // ----------------------------
  // PHOTO save
  // ----------------------------
  Future<String> _persistImageToAppDir(File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = "pp_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final saved = File("${dir.path}/$fileName");

    final bytes = await imageFile.readAsBytes();
    await saved.writeAsBytes(bytes, flush: true);
    return saved.path;
  }

  Future<void> _pickCropAndSavePp(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;

      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xff050c20),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true),
        ],
      );

      if (cropped == null) return;

      final newPath = await _persistImageToAppDir(File(cropped.path));

      final oldPath = _currentUser?.photoPath ?? '';
      if (oldPath.isNotEmpty) {
        final f = File(oldPath);
        if (await f.exists()) await f.delete();
      }

      await _db.updateLocalUser(photoPath: newPath);
      await _loadUser();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile picture updated ✅"),
          backgroundColor: Color(0xff050c20),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showPpSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.photo_camera_solid),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickCropAndSavePp(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.photo),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickCropAndSavePp(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNameDialog() async {
    final fnameCtrl = TextEditingController(text: _currentUser?.fname ?? '');
    final lnameCtrl = TextEditingController(text: _currentUser?.lname ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Name', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fnameCtrl,
              decoration: const InputDecoration(
                hintText: "First Name",
                prefixIcon: Icon(CupertinoIcons.person_fill),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lnameCtrl,
              decoration: const InputDecoration(
                hintText: "Last Name",
                prefixIcon: Icon(CupertinoIcons.person_fill),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xff050c20)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Save",
              style: TextStyle(color: Color(0xff050c20)),
            ),
          ),
        ],
      ),
    );

    if (saved != true) return;

    await _db.updateLocalUser(
      fname: fnameCtrl.text.trim(),
      lname: lnameCtrl.text.trim(),
    );

    await _loadUser();
  }

  void _onAvatarTap() {
    final path = _currentUser?.photoPath ?? '';
    final hasPhoto = path.isNotEmpty && File(path).existsSync();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Center(child: Text('Profile Picture')),
        content: SizedBox(
          width: 260,
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: hasPhoto
                ? Image.file(File(path), fit: BoxFit.cover)
                : Container(
                    color: Colors.grey.shade200,
                    child: const Icon(CupertinoIcons.person_fill, size: 90),
                  ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Color(0xff050c20)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPpSourceSheet();
            },
            child: const Text(
              "Modify",
              style: TextStyle(color: Color(0xff050c20)),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // STATUS/Color/Label for today cards
  // ----------------------------
  ({String status, Color color}) _computeTodayStatusAndColor(
    Task task,
    DateTime now,
    DateTime today,
  ) {
    DateTime? start;
    DateTime? end;

    try {
      if ((task.startTime ?? '').trim().isNotEmpty) {
        final parsed = DateFormat.jm().parse(task.startTime!);
        start = DateTime(
          today.year,
          today.month,
          today.day,
          parsed.hour,
          parsed.minute,
        );
      }
      if ((task.endTime ?? '').trim().isNotEmpty) {
        final parsedEnd = DateFormat.jm().parse(task.endTime!);
        end = DateTime(
          today.year,
          today.month,
          today.day,
          parsedEnd.hour,
          parsedEnd.minute,
        );
      }
    } catch (_) {}

    if (end != null && end.isBefore(now)) {
      return (status: 'overdue', color: Colors.red);
    }

    if (start != null &&
        end != null &&
        now.isAfter(start) &&
        now.isBefore(end)) {
      return (status: 'in_progress', color: Colors.orange);
    }

    if (start != null && start.isAfter(now)) {
      return (status: 'next', color: Colors.blue);
    }

    final raw = task.status.toLowerCase();
    if (raw == 'done') return (status: 'done', color: Colors.green);
    if (raw == 'in progress' || raw == 'in_progress') {
      return (status: 'in_progress', color: Colors.orange);
    }

    // If no time set yet -> grey + special status
    final hasStart = (task.startTime ?? '').trim().isNotEmpty;
    final hasEnd = (task.endTime ?? '').trim().isNotEmpty;

    if (!hasStart || !hasEnd) {
      return (status: 'no_time', color: Colors.grey);
    }
    return (status: 'todo', color: Colors.grey);
  }

  String _statusLabel(_DashTaskItem item) {
    final time = (item.task.startTime ?? '').trim().isNotEmpty
        ? item.task.startTime!
        : "--:--";

    switch (item.status) {
      case "overdue":
        return "${item.task.title} is overdue!\nEnded at ${item.task.endTime ?? '--:--'}";
      case "in_progress":
        return "It's time for: ${item.task.title} ($time)";
      case "next":
        return "Next: ${item.task.title} at $time";
      case "no_time":
        return "${item.task.title} (No time set yet)";

      default:
        return "${item.task.title} (No time set)";
    }
  }

  // ----------------------------
  // BUILD TASK LIST
  // ----------------------------
  Widget _buildTaskList() {
    if (todayTasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          "No tasks for today",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: todayTasks.map((item) {
        return GestureDetector(
          onTap: _openSchedulePage,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: item.color.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(item),
                  style: TextStyle(
                    color: item.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.task.subtitle,
                  style: TextStyle(
                    color: item.color.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'D A S H B O A R D',
          style: TextStyle(color: Color(0xff050c20)),
        ),
        actions: [
          Row(
            children: [
              IconButton(
                tooltip: "Settings",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ).then((_) => _loadDashboardTasks());
                },
                icon: const Icon(
                  CupertinoIcons.settings,
                  color: Color(0xff050c20),
                ),
              ),
              SizedBox(width: 10),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildStats(),
                const SizedBox(height: 18),
                _buildTodayCard(),
                const SizedBox(height: 18),
                _buildTaskList(),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MyNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    final fullName =
        ((_currentUser?.fname ?? '').trim().isEmpty &&
            (_currentUser?.lname ?? '').trim().isEmpty)
        ? "Guest"
        : "${_currentUser?.fname ?? ''} ${_currentUser?.lname ?? ''}".trim();

    final path = _currentUser?.photoPath ?? '';
    final hasPhoto = path.isNotEmpty && File(path).existsSync();

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _onAvatarTap,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              backgroundImage: hasPhoto ? FileImage(File(path)) : null,
              child: !hasPhoto
                  ? const Icon(CupertinoIcons.person_fill, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _timeGreetingIcon(),
                      size: 18,
                      color: const Color(0xff050c20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${_timeGreetingText()},",
                      style: const TextStyle(
                        color: Color(0xff050c20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _editNameDialog,
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xff050c20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: StatTile(
            icon: CupertinoIcons.book_fill,
            label: 'Notes',
            value: '$totalTasks',
            iconColor: Colors.orange,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: StatTile(
            icon: CupertinoIcons.checkmark_seal_fill,
            label: 'Tasks',
            value: '$completedToday',
            iconColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xff050c20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Keep up the streak! You've completed $completedToday items today.",
            style: const TextStyle(color: Color(0xff050c20)),
          ),
        ],
      ),
    );
  }
}

class _DashTaskItem {
  final Task task;
  final String status;
  final Color color;

  _DashTaskItem({
    required this.task,
    required this.status,
    required this.color,
  });
}
