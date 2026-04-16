// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:josephs_vs_01/components/mynavbar.dart';
import 'package:josephs_vs_01/components/myschedulecard.dart';
import 'package:josephs_vs_01/main.dart'; // ✅ for AppThemeKey (original theme)
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

  bool _showMonthPicker = false;
  DateTime _anchorDate = DateTime.now();

  int selectedDayIndex = 0;
  late List<_DayItem> _days;

  //to slide the day selector
  late PageController _pageController;

  List<Task> _tasksForDay = [];
  bool _loading = false;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  //saving date occurence
  DateTime _occurrenceDateFor(Task task, DateTime selectedDate) {
    return _dateOnly(selectedDate);
  }

  //calculating the number of occurence * 12 for the year

  bool _shouldShowTaskOnDate(Task task, DateTime selectedDate) {
    final taskDate = _dateOnly(task.date);
    final targetDate = _dateOnly(selectedDate);

    if (targetDate.isBefore(taskDate)) return false;

    if (task.isRecurring != true) {
      return _isSameDate(taskDate, targetDate);
    }

    final recurrence = (task.recurrenceType ?? '').toLowerCase();

    switch (recurrence) {
      case 'daily':
        return !targetDate.isBefore(taskDate);

      case 'weekly':
        final diffDays = targetDate.difference(taskDate).inDays;
        return diffDays >= 0 && diffDays % 7 == 0;

      case 'monthly':
        if (targetDate.day != taskDate.day) return false;

        final monthDiff =
            (targetDate.year - taskDate.year) * 12 +
            (targetDate.month - taskDate.month);

        return monthDiff >= 0;

      default:
        return _isSameDate(taskDate, targetDate);
    }
  }

  @override
  void initState() {
    super.initState();
    _days = _generateDaysFrom(_anchorDate);
    _loadTasksForSelectedDay();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // =========================
  // DAYS GENERATION
  // =========================

  List<_DayItem> _generateDaysFrom(DateTime anchor) {
    final base = DateTime(anchor.year, anchor.month, anchor.day);

    return List.generate(4, (i) {
      final date = base.add(Duration(days: i));
      return _DayItem(DateFormat('EEE').format(date), date);
    });
  }

  DateTime get _selectedDate => _days[selectedDayIndex].date;

  // =========================
  // LOAD TASKS
  // =========================

  Future<void> _loadTasksForSelectedDay() async {
    setState(() => _loading = true);

    try {
      final allRows = await _db.getTasks();

      final rows = allRows
          .where((t) => _shouldShowTaskOnDate(t, _selectedDate))
          .toList();

      rows.sort((a, b) {
        final pa = _statusPriority(_computeStatusForDate(a, _selectedDate));
        final pb = _statusPriority(_computeStatusForDate(b, _selectedDate));
        if (pa != pb) return pa.compareTo(pb);

        DateTime build(Task t) {
          final baseDate = _occurrenceDateFor(t, _selectedDate);

          if (t.startTime == null || t.startTime!.trim().isEmpty) {
            return DateTime(baseDate.year, baseDate.month, baseDate.day);
          }

          final parsed = DateFormat.jm().parse(t.startTime!);
          return DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day,
            parsed.hour,
            parsed.minute,
          );
        }

        return build(a).compareTo(build(b));
      });

      if (!mounted) return;
      setState(() => _tasksForDay = rows);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _statusPriority(String status) {
    switch (status) {
      case 'overdue':
        return 0;
      case 'in_progress':
        return 1;
      case 'todo':
        return 2;
      case 'done':
        return 3;
      default:
        return 4;
    }
  }

  String _computeStatusForDate(Task t, DateTime selectedDate) {
    final raw = t.status.toLowerCase();
    if (raw == 'done') return 'done';

    final hasStart = t.startTime != null && t.startTime!.trim().isNotEmpty;
    final hasEnd = t.endTime != null && t.endTime!.trim().isNotEmpty;

    if (!hasStart || !hasEnd) {
      return 'todo';
    }

    final baseDate = _occurrenceDateFor(t, selectedDate);
    final now = DateTime.now();

    DateTime parse(String time) {
      final parsed = DateFormat.jm().parse(time);
      return DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        parsed.hour,
        parsed.minute,
      );
    }

    final start = parse(t.startTime!);
    DateTime end = parse(t.endTime!);

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    if (now.isBefore(start)) return 'todo';
    if (now.isAfter(start) && now.isBefore(end)) return 'in_progress';
    if (now.isAfter(end)) return 'overdue';

    return 'todo';
  }

  // =========================
  // CALENDAR PICKER
  // =========================

  void _onMonthPicked(DateTime picked) async {
    setState(() {
      _anchorDate = picked;
      _days = _generateDaysFrom(picked);
      selectedDayIndex = 0;
      _showMonthPicker = false;
    });

    await _loadTasksForSelectedDay();
  }

  // =========================
  // TIME PICKER (Cupertino wheel preserved)
  // =========================

  Future<void> _setTaskTime(Task task) async {
    if ((task.status).toLowerCase() == 'done') return;

    DateTime parseOnTaskDay(String? t) {
      if (t == null || t.trim().isEmpty) {
        final now = DateTime.now();
        return DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
          now.hour,
          now.minute,
        );
      }

      final parsed = DateFormat.jm().parse(t);
      return DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        parsed.hour,
        parsed.minute,
      );
    }

    DateTime startDT = parseOnTaskDay(task.startTime);
    DateTime endDT = parseOnTaskDay(task.endTime);

    if (!endDT.isAfter(startDT)) {
      endDT = startDT.add(const Duration(minutes: 30));
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;

            final isOriginal =
                theme.extension<AppThemeKey>()?.key == "original";

            final primaryColor = isOriginal
                ? const Color(0xff050c20)
                : scheme.primary;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await _db.updateTask(
                          id: task.id!,
                          status: task.status,
                          title: task.title,
                          subtitle: task.subtitle,
                          date: task.date,
                          startTime: null,
                          endTime: null,
                        );

                        await NotificationServices.instance.cancelNotification(
                          task.id!,
                        );

                        if (mounted) {
                          await _loadTasksForSelectedDay();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        "Clear",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                    const Text(
                      "Set Start & End",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    TextButton(
                      onPressed: () async {
                        if (!endDT.isAfter(startDT)) return;

                        await _db.updateTask(
                          id: task.id!,
                          status: task.status,
                          title: task.title,
                          subtitle: task.subtitle,
                          date: task.date,
                          startTime: DateFormat.jm().format(startDT),
                          endTime: DateFormat.jm().format(endDT),
                        );

                        await NotificationServices.instance.cancelNotification(
                          task.id!,
                        );

                        if (startDT.isAfter(DateTime.now())) {
                          await NotificationServices.instance
                              .scheduleNotification(
                                id: task.id!,
                                title: task.title,
                                body: "It's time for: ${task.title}",
                                scheduledDate: startDT,
                              );
                        }

                        if (mounted) {
                          await _loadTasksForSelectedDay();
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        "Done",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(),

                SizedBox(
                  height: 120,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false,
                    initialDateTime: startDT,
                    onDateTimeChanged: (dt) {
                      startDT = dt;
                      if (!endDT.isAfter(startDT)) {
                        endDT = startDT.add(const Duration(minutes: 30));
                      }
                    },
                  ),
                ),

                SizedBox(
                  height: 120,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false,
                    initialDateTime: endDT,
                    onDateTimeChanged: (dt) {
                      endDT = dt;
                    },
                  ),
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bool isOriginal =
        Theme.of(context).extension<AppThemeKey>()?.key == "original";
    final Color brandColor = isOriginal
        ? const Color(0xff050c20)
        : scheme.primary;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'M Y   S C H E D U L E',
          style: TextStyle(color: scheme.onSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.calendar, color: scheme.onSurface),
            onPressed: () {
              setState(() => _showMonthPicker = !_showMonthPicker);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ======================
            // 4 DAY SELECTOR
            // ======================
            _buildDaySelector(),

            // ======================
            // MONTH PICKER
            // ======================
            if (_showMonthPicker)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isOriginal
                        ? Colors.grey.shade100
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Theme(
                    data: isOriginal
                        ? Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: const Color(0xff050c20),
                            ),
                          )
                        : Theme.of(context),
                    child: CalendarDatePicker(
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: _onMonthPicked,
                    ),
                  ),
                ),
              ),

            // ======================
            // TASK LIST
            // ======================
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadTasksForSelectedDay,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _tasksForDay.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final t = _tasksForDay[index];
                          final status = _computeStatusForDate(
                            t,
                            _selectedDate,
                          );

                          return MyScheduleCard(
                            title: t.title,
                            subtitle: t.subtitle,
                            start: t.startTime ?? '--:--',
                            end: t.endTime ?? '--:--',
                            status: status,
                            avatarColor: brandColor,
                            onClockTap: () => _setTaskTime(t),
                            clockColor: brandColor,
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

  Widget _buildDaySelector() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bool isOriginal = theme.extension<AppThemeKey>()?.key == "original";

    const Color brandColor = Color(0xff050c20);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: isOriginal
            ? Colors.grey.shade100
            : (isDark
                  ? scheme.surfaceContainerHigh
                  : scheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              DateFormat('MMMM yyyy').format(_selectedDate),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isOriginal ? brandColor : scheme.onSurface,
              ),
            ),
          ),
          SizedBox(
            height: 80,
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, page) {
                final pageDays = _generateDaysFrom(
                  _anchorDate.add(Duration(days: page * 4)),
                );

                return Row(
                  children: List.generate(pageDays.length, (i) {
                    final isSelected = selectedDayIndex == i;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AspectRatio(
                          aspectRatio: 0.78,
                          child: GestureDetector(
                            onTap: () async {
                              setState(() {
                                _days = pageDays;
                                selectedDayIndex = i;
                              });
                              await _loadTasksForSelectedDay();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: isOriginal
                                    ? (isSelected ? brandColor : Colors.white)
                                    : (isSelected
                                          ? scheme.primary
                                          : scheme.surface),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: isOriginal
                                              ? brandColor.withOpacity(.25)
                                              : scheme.primary.withOpacity(.35),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(pageDays[i].date),
                                    style: TextStyle(
                                      color: isOriginal
                                          ? (isSelected
                                                ? Colors.white
                                                : brandColor)
                                          : (isSelected
                                                ? scheme.onPrimary
                                                : scheme.onSurface.withOpacity(
                                                    0.7,
                                                  )),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    pageDays[i].date.day.toString(),
                                    style: TextStyle(
                                      color: isOriginal
                                          ? (isSelected
                                                ? Colors.white
                                                : brandColor)
                                          : (isSelected
                                                ? scheme.onPrimary
                                                : scheme.onSurface),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
              onPageChanged: (page) async {
                final newDays = _generateDaysFrom(
                  _anchorDate.add(Duration(days: page * 4)),
                );

                setState(() {
                  _days = newDays;
                  selectedDayIndex = 0;
                });

                await _loadTasksForSelectedDay();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayItem {
  final String label;
  final DateTime date;
  const _DayItem(this.label, this.date);
}
