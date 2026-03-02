// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages, deprecated_member_use

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:josephs_vs_01/models/tasks.dart';
import 'package:path_provider/path_provider.dart';

import 'package:josephs_vs_01/components/mynavbar.dart';
import 'package:josephs_vs_01/components/stattile.dart';
import 'package:josephs_vs_01/pages/settings.dart';
import 'package:josephs_vs_01/management/database.dart';
import 'package:josephs_vs_01/models/users.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DatabaseManager _db = DatabaseManager();
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

  Future<void> _loadUser() async {
    final u = await _db.getLocalUser();
    if (!mounted) return;
    setState(() => _currentUser = u);
  }

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

      final sameDay =
          taskDay.year == today.year &&
          taskDay.month == today.month &&
          taskDay.day == today.day;

      final isDone = (t.status).toLowerCase() == 'done';

      // Completed today counter
      if (isDone && sameDay) {
        completed++;
        continue;
      }

      // Only display today tasks in list
      if (!sameDay) continue;

      final res = _computeTodayStatusAndColor(t, now, today);
      if (res.status == 'overdue') overdue++;

      computed.add(
        _DashTaskItem(task: t, status: res.status, color: res.color),
      );
    }

    // Sort by start time
    int timeKey(String? st, String status) {
      if (status == 'no_time') return 24 * 60 + 2;
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

    final hasStart = (task.startTime ?? '').trim().isNotEmpty;
    final hasEnd = (task.endTime ?? '').trim().isNotEmpty;

    if (!hasStart || !hasEnd) {
      return (status: 'no_time', color: Colors.grey);
    }

    return (status: 'todo', color: Colors.grey);
  }

  // ================= GREETING =================

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

  // ================= PHOTO =================

  Future<String> _persistImage(File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = "pp_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final saved = File("${dir.path}/$fileName");
    await saved.writeAsBytes(await imageFile.readAsBytes());
    return saved.path;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      );

      if (cropped == null) return;

      final newPath = await _persistImage(File(cropped.path));

      await _db.updateLocalUser(photoPath: newPath);
      await _loadUser();
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.photo_camera),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.photo),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onAvatarTap() {
    final scheme = Theme.of(context).colorScheme;
    final path = _currentUser?.photoPath ?? '';
    final hasPhoto = path.isNotEmpty && File(path).existsSync();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Center(
          child: Text(
            "Profile Picture",
            style: TextStyle(color: scheme.onSurface),
          ),
        ),
        content: SizedBox(
          width: 260,
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: hasPhoto
                ? Image.file(File(path), fit: BoxFit.cover)
                : Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      CupertinoIcons.person_fill,
                      size: 90,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: scheme.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPhotoOptions();
            },
            child: Text("Modify", style: TextStyle(color: scheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(String hint, TextEditingController controller) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.onSurface),
        ),
      ),
    );
  }

  Future<void> _editName() async {
    final scheme = Theme.of(context).colorScheme;

    final fnameCtrl = TextEditingController(text: _currentUser?.fname ?? '');
    final lnameCtrl = TextEditingController(text: _currentUser?.lname ?? '');

    final saved = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: scheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Name",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),

              const SizedBox(height: 24),

              _dialogField("First Name", fnameCtrl),
              const SizedBox(height: 16),
              _dialogField("Last Name", lnameCtrl),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: scheme.onSurface),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      "Save",
                      style: TextStyle(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true) return;

    await _db.updateLocalUser(
      fname: fnameCtrl.text.trim(),
      lname: lnameCtrl.text.trim(),
    );

    await _loadUser();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'D A S H B O A R D',
          style: TextStyle(color: scheme.onSurface),
        ),
        backgroundColor: scheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.settings, color: scheme.onSurface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
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
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MyNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bool isOriginal =
        theme.brightness == Brightness.light &&
        scheme.primary == const Color(0xFF050C20);

    final fullName =
        ((_currentUser?.fname ?? '').trim().isEmpty &&
            (_currentUser?.lname ?? '').trim().isEmpty)
        ? "Guest"
        : "${_currentUser?.fname ?? ''} ${_currentUser?.lname ?? ''}".trim();

    final path = _currentUser?.photoPath ?? '';
    final hasPhoto = path.isNotEmpty && File(path).existsSync();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isOriginal
            ? Colors
                  .grey
                  .shade100 // 🔥 your real original color
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _onAvatarTap,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: isOriginal ? Colors.white : scheme.surface,
              backgroundImage: hasPhoto ? FileImage(File(path)) : null,
              child: !hasPhoto
                  ? Icon(
                      CupertinoIcons.person_fill,
                      color: isOriginal ? Colors.grey : scheme.onSurfaceVariant,
                    )
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
                      color: isOriginal
                          ? const Color(0xFF050C20)
                          : scheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${_timeGreetingText()},",
                      style: TextStyle(
                        color: isOriginal
                            ? const Color(0xFF050C20)
                            : scheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _editName,
                  child: Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 16,
                      color: isOriginal
                          ? const Color(0xFF050C20)
                          : scheme.onSurface,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bool isOriginal =
        theme.brightness == Brightness.light &&
        scheme.primary == const Color(0xFF050C20);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: StatTile(
            icon: CupertinoIcons.book_fill,
            label: 'Notes',
            value: '$totalTasks',
            iconColor: isOriginal
                ? Colors
                      .orange // 🔥 your original Notes color
                : scheme.primary,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: StatTile(
            icon: CupertinoIcons.checkmark_seal_fill,
            label: 'Tasks',
            value: '$completedToday',
            iconColor: isOriginal
                ? Colors
                      .green // 🔥 your original Tasks color
                : scheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayCard() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bool isOriginal =
        theme.brightness == Brightness.light &&
        scheme.primary == const Color(0xFF050C20);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOriginal ? Colors.white : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isOriginal
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOriginal ? const Color(0xFF050C20) : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Keep up the streak! You've completed $completedToday items today.",
            style: TextStyle(
              color: isOriginal ? const Color(0xFF050C20) : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    if (todayTasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          "No tasks for today",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: todayTasks.map((item) {
        return Container(
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
                item.task.title,
                style: TextStyle(
                  color: item.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.task.subtitle,
                style: TextStyle(color: item.color.withOpacity(0.7)),
              ),
            ],
          ),
        );
      }).toList(),
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
