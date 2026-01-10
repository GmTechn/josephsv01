// ignore_for_file: deprecated_member_use, use_build_context_synchronously, depend_on_referenced_packages

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:josephs_vs_01/components/mynavbar.dart';
import 'package:josephs_vs_01/components/myschedulecard.dart';
import 'package:josephs_vs_01/management/database.dart';
import 'package:josephs_vs_01/management/notifications.dart';
import 'package:josephs_vs_01/models/tasks.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final DatabaseManager _db = DatabaseManager();

  int selectedDayIndex = 0;
  late final List<_DayItem> _days;

  List<Task> _tasksForDay = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _days = _generateDays();
    _loadTasksForSelectedDay();
  }

  List<_DayItem> _generateDays() {
    final today = DateTime.now();
    return List.generate(4, (i) {
      final date = today.add(Duration(days: i));
      return _DayItem(
        _weekdayLabel(date.weekday),
        DateTime(date.year, date.month, date.day),
      );
    });
  }

  DateTime get _selectedDate => _days[selectedDayIndex].date;

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  Future<void> _loadTasksForSelectedDay() async {
    setState(() => _loading = true);
    try {
      final rows = await _db.getTasks(day: _selectedDate);
      if (!mounted) return;
      setState(() => _tasksForDay = rows);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // status for schedule card
  String _computeStatus(Task t) {
    final raw = (t.status).trim().toLowerCase();
    if (raw == 'done') return 'done';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(t.date.year, t.date.month, t.date.day);

    if (taskDay.isBefore(today)) return 'overdue';

    final hasStart = (t.startTime ?? '').trim().isNotEmpty;
    final hasEnd = (t.endTime ?? '').trim().isNotEmpty;
    if (!hasStart || !hasEnd) return 'todo';

    try {
      final s = DateFormat.jm().parse(t.startTime!);
      final e = DateFormat.jm().parse(t.endTime!);
      final start = DateTime(
        taskDay.year,
        taskDay.month,
        taskDay.day,
        s.hour,
        s.minute,
      );
      final end = DateTime(
        taskDay.year,
        taskDay.month,
        taskDay.day,
        e.hour,
        e.minute,
      );

      if (now.isAfter(end)) return 'overdue';
      if (now.isAfter(start) && now.isBefore(end)) return 'in_progress';
    } catch (_) {}

    return 'todo';
  }

  Color _getClockColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _setTaskTime(Task task) async {
    if ((task.status).toLowerCase() == 'done') return;

    // Helpers
    DateTime baseDay() =>
        DateTime(task.date.year, task.date.month, task.date.day);

    DateTime defaultNowOnTaskDay() {
      final now = DateTime.now();
      return DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        now.hour,
        now.minute,
      );
    }

    DateTime parseOnTaskDay(String? t) {
      if (t == null || t.trim().isEmpty) return defaultNowOnTaskDay();
      try {
        final dt = DateFormat.jm().parse(t);
        return DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
          dt.hour,
          dt.minute,
        );
      } catch (_) {
        return defaultNowOnTaskDay();
      }
    }

    String fmt(DateTime dt) => DateFormat.jm().format(dt);

    int mins(DateTime dt) => dt.hour * 60 + dt.minute;

    bool saving = false;

    DateTime startDT = parseOnTaskDay(task.startTime);
    DateTime endDT = parseOnTaskDay(task.endTime);

    // If end is invalid compared to start, set end = start + 30 min (safe default)
    if (mins(endDT) <= mins(startDT)) {
      endDT = startDT.add(const Duration(minutes: 30));
    }

    Future<void> saveBoth() async {
      if (saving) return;
      saving = true;

      // validate end > start
      if (mins(endDT) <= mins(startDT)) {
        saving = false;
        return;
      }

      await _db.updateTask(
        id: task.id!,
        status: task.status,
        title: task.title,
        subtitle: task.subtitle,
        date: task.date,
        startTime: fmt(startDT),
        endTime: fmt(endDT),
      );

      // reschedule notification at START
      await NotificationServices.instance.cancelNotification(task.id!);

      await NotificationServices.instance.scheduleNotification(
        id: task.id!,
        title: task.title,
        body: "It's time for: ${task.title}",
        scheduledDate: startDT,
      );

      saving = false;
    }

    Future<void> clearTimes() async {
      if (saving) return;
      saving = true;

      await _db.updateTask(
        id: task.id!,
        status: task.status,
        title: task.title,
        subtitle: task.subtitle,
        date: task.date,
        startTime: null,
        endTime: null,
      );

      await NotificationServices.instance.cancelNotification(task.id!);

      saving = false;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final bool invalidRange = mins(endDT) <= mins(startDT);

            Future<void> onStartChanged(DateTime dt) async {
              startDT = DateTime(
                baseDay().year,
                baseDay().month,
                baseDay().day,
                dt.hour,
                dt.minute,
              );

              // If start >= end, push end forward automatically (nice UX)
              if (mins(endDT) <= mins(startDT)) {
                endDT = startDT.add(const Duration(minutes: 30));
              }

              setStateSheet(() {});
              await saveBoth();
            }

            Future<void> onEndChanged(DateTime dt) async {
              endDT = DateTime(
                baseDay().year,
                baseDay().month,
                baseDay().day,
                dt.hour,
                dt.minute,
              );

              setStateSheet(() {});
              // Only save if valid
              if (mins(endDT) > mins(startDT)) {
                await saveBoth();
              }
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                      MediaQuery.of(context).padding.bottom +
                      12,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await clearTimes();
                              if (mounted) await _loadTasksForSelectedDay();
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Clear",
                              style: TextStyle(color: Color(0xff050c20)),
                            ),
                          ),
                          const Text(
                            "Set Start & End",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xff050c20),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (mounted) await _loadTasksForSelectedDay();
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Done",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // START
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        "Start",
                        style: TextStyle(
                          color: Color(0xff050c20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 128,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: false,
                        initialDateTime: startDT,
                        onDateTimeChanged: (dt) => onStartChanged(dt),
                      ),
                    ),

                    // END
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        "End",
                        style: TextStyle(
                          color: Color(0xff050c20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 140,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: false,
                        initialDateTime: endDT,
                        onDateTimeChanged: (dt) => onEndChanged(dt),
                      ),
                    ),

                    const SizedBox(height: 6),

                    if (invalidRange)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "End time must be after start time.",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Scrolling saves automatically.",
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    await _loadTasksForSelectedDay();
  }

  @override
  Widget build(BuildContext context) {
    const pillColor = Color(0xff050c20);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('M Y   S C H E D U L E'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDaySelector(pillColor),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _tasksForDay.isEmpty
                  ? const Center(child: _EmptyScheduleState())
                  : RefreshIndicator(
                      onRefresh: _loadTasksForSelectedDay,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _tasksForDay.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final t = _tasksForDay[index];
                          final status = _computeStatus(t);
                          final clockColor = _getClockColor(status);

                          return MyScheduleCard(
                            title: t.title,
                            subtitle: t.subtitle,
                            start: (t.startTime ?? '').isNotEmpty
                                ? t.startTime!
                                : '--:--',
                            end: (t.endTime ?? '').isNotEmpty
                                ? t.endTime!
                                : '--:--',
                            status: status,
                            avatarColor: Colors.blue.shade300,
                            onClockTap: () => _setTaskTime(t),
                            clockColor: clockColor,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MyNavBar(currentIndex: 2),
    );
  }

  Widget _buildDaySelector(Color pillColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(_days.length, (i) {
          final isSel = i == selectedDayIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () async {
                setState(() => selectedDayIndex = i);
                await _loadTasksForSelectedDay();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSel ? pillColor : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      _days[i].label,
                      style: TextStyle(
                        color: isSel ? Colors.white : pillColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _days[i].date.day.toString(),
                      style: TextStyle(
                        color: isSel ? Colors.white : pillColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DayItem {
  final String label;
  final DateTime date;
  const _DayItem(this.label, this.date);
}

class _EmptyScheduleState extends StatelessWidget {
  const _EmptyScheduleState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Text(
        "No tasks for this day",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }
}
