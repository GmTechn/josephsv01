import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:josephs_vs_01/components/mynavbar.dart';
import 'package:josephs_vs_01/main.dart';
import 'package:josephs_vs_01/management/database.dart';
import 'package:josephs_vs_01/models/tasks.dart';

class WeeklyOverviewPage extends StatefulWidget {
  const WeeklyOverviewPage({super.key});

  @override
  State<WeeklyOverviewPage> createState() => _WeeklyOverviewPageState();
}

class _WeeklyOverviewPageState extends State<WeeklyOverviewPage> {
  final DatabaseManager _db = DatabaseManager();

  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  List<Task> _allTasks = [];
  bool _loading = true;

  // =========================================================
  // DATE HELPERS
  // =========================================================

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  DateTime get _monthStart {
    return DateTime(_displayedMonth.year, _displayedMonth.month, 1);
  }

  DateTime get _monthEnd {
    return DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
  }

  // Calendar starts on Sunday like Apple Calendar
  DateTime get _calendarStart {
    final firstDay = _monthStart;

    final daysFromSunday = firstDay.weekday % 7;

    return firstDay.subtract(Duration(days: daysFromSunday));
  }

  DateTime get _calendarEnd {
    final lastDay = _monthEnd;

    final daysUntilSaturday = 6 - (lastDay.weekday % 7);

    return lastDay.add(Duration(days: daysUntilSaturday));
  }

  List<DateTime> get _calendarDays {
    final totalDays = _calendarEnd.difference(_calendarStart).inDays + 1;

    return List.generate(
      totalDays,
      (index) => _calendarStart.add(Duration(days: index)),
    );
  }

  List<List<DateTime>> get _calendarWeeks {
    final days = _calendarDays;

    final weeks = <List<DateTime>>[];

    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }

    return weeks;
  }

  void _showEmptyDayPopup(DateTime day) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            DateFormat('EEEE, MMMM d').format(day),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Nothing planned for this day.',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: .65)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // RECURRING TASK LOGIC
  // SAME AS YOUR SCHEDULE PAGE
  // =========================================================

  bool _shouldShowTaskOnDate(Task task, DateTime selectedDate) {
    final taskDate = _dateOnly(task.date);
    final targetDate = _dateOnly(selectedDate);

    if (targetDate.isBefore(taskDate)) {
      return false;
    }

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
        if (targetDate.day != taskDate.day) {
          return false;
        }

        final monthDiff =
            (targetDate.year - taskDate.year) * 12 +
            (targetDate.month - taskDate.month);

        return monthDiff >= 0;

      default:
        return _isSameDate(taskDate, targetDate);
    }
  }

  // =========================================================
  // STATUS
  // =========================================================

  DateTime _occurrenceDateFor(Task task, DateTime selectedDate) {
    return _dateOnly(selectedDate);
  }

  String _computeStatusForDate(Task task, DateTime selectedDate) {
    final raw = task.status.toLowerCase();

    if (raw == 'done') {
      return 'done';
    }

    final hasStart =
        task.startTime != null && task.startTime!.trim().isNotEmpty;

    final hasEnd = task.endTime != null && task.endTime!.trim().isNotEmpty;

    if (!hasStart || !hasEnd) {
      return 'todo';
    }

    final baseDate = _occurrenceDateFor(task, selectedDate);

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

    final start = parse(task.startTime!);

    DateTime end = parse(task.endTime!);

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    if (now.isBefore(start)) {
      return 'todo';
    }

    if (now.isAfter(start) && now.isBefore(end)) {
      return 'in_progress';
    }

    if (now.isAfter(end)) {
      return 'overdue';
    }

    return 'todo';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;

      case 'in_progress':
        return Colors.orange;

      case 'overdue':
        return Colors.red.shade900;

      case 'todo':
      default:
        return Colors.red;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'done':
        return 'Done';

      case 'in_progress':
        return 'In Progress';

      case 'overdue':
        return 'Overdue';

      default:
        return 'To Do';
    }
  }

  // =========================================================
  // DATABASE
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
    });

    try {
      final tasks = await _db.getTasks();

      if (!mounted) return;

      setState(() {
        _allTasks = tasks;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =========================================================
  // TASKS FOR DATE
  // =========================================================

  List<Task> _tasksForDate(DateTime date) {
    final tasks = _allTasks
        .where((task) => _shouldShowTaskOnDate(task, date))
        .toList();

    tasks.sort((a, b) {
      DateTime taskTime(Task task) {
        if (task.startTime == null || task.startTime!.trim().isEmpty) {
          return DateTime(date.year, date.month, date.day);
        }

        try {
          final parsed = DateFormat.jm().parse(task.startTime!);

          return DateTime(
            date.year,
            date.month,
            date.day,
            parsed.hour,
            parsed.minute,
          );
        } catch (_) {
          return DateTime(date.year, date.month, date.day);
        }
      }

      return taskTime(a).compareTo(taskTime(b));
    });

    return tasks;
  }

  // =========================================================
  // MONTH NAVIGATION
  // =========================================================

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  void _goToToday() {
    final now = DateTime.now();

    setState(() {
      _displayedMonth = DateTime(now.year, now.month);
    });
  }

  // =========================================================
  // MONTH STATISTICS
  // =========================================================

  int get _totalTasks {
    int total = 0;

    for (
      DateTime day = _monthStart;
      !day.isAfter(_monthEnd);
      day = day.add(const Duration(days: 1))
    ) {
      total += _tasksForDate(day).length;
    }

    return total;
  }

  int get _doneTasks {
    int total = 0;

    for (
      DateTime day = _monthStart;
      !day.isAfter(_monthEnd);
      day = day.add(const Duration(days: 1))
    ) {
      final tasks = _tasksForDate(day);

      for (final task in tasks) {
        final status = _computeStatusForDate(task, day);

        if (status == 'done') {
          total++;
        }
      }
    }

    return total;
  }

  int get _progress {
    if (_totalTasks == 0) {
      return 0;
    }

    return ((_doneTasks / _totalTasks) * 100).round();
  }

  String get _motivationMessage {
    if (_totalTasks == 0) {
      return 'A fresh month starts here ✨';
    }

    if (_progress == 0) {
      return 'Ready when you are ✨';
    }

    if (_progress < 30) {
      return 'You’ve started — keep going 💪';
    }

    if (_progress < 60) {
      return 'Nice progress — keep the momentum 🔥';
    }

    if (_progress < 90) {
      return 'You’re doing great 🚀';
    }

    if (_progress < 100) {
      return 'Almost there ✨';
    }

    return 'Amazing work 🎉';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final scheme = theme.colorScheme;

    final bool isOriginal = theme.extension<AppThemeKey>()?.key == "original";

    const Color brandColor = Color(0xff050c20);

    final primaryColor = isOriginal ? brandColor : scheme.primary;

    return Scaffold(
      backgroundColor: scheme.surface,

      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'M Y   C A L E N D A R',
          style: TextStyle(color: scheme.onSurface),
        ),
      ),

      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : RefreshIndicator(
                onRefresh: _loadTasks,

                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),

                  children: [
                    // =========================================
                    // MONTH HEADER
                    // =========================================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,

                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('MMMM').format(_displayedMonth),

                            style: TextStyle(
                              fontSize: 24,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: isOriginal ? brandColor : scheme.onSurface,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: _previousMonth,
                          icon: Icon(
                            CupertinoIcons.chevron_left,
                            color: primaryColor,
                          ),
                        ),

                        TextButton(
                          onPressed: _goToToday,
                          child: Text(
                            'Today',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: _nextMonth,
                          icon: Icon(
                            CupertinoIcons.chevron_right,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),

                    Text(
                      '${_displayedMonth.year}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: .45),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =========================================
                    // MOTIVATION / STATS
                    // =========================================
                    Row(
                      children: [
                        Text(
                          '$_totalTasks Tasks',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '|',
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: .25),
                            ),
                          ),
                        ),

                        Text(
                          '$_doneTasks Done',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '|',
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: .25),
                            ),
                          ),
                        ),

                        Text(
                          '$_progress%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _motivationMessage,

                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: .50),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // =========================================
                    // WEEKDAY HEADERS
                    // =========================================
                    Row(
                      children: const [
                        _WeekDayLabel('S'),
                        _WeekDayLabel('M'),
                        _WeekDayLabel('T'),
                        _WeekDayLabel('W'),
                        _WeekDayLabel('T'),
                        _WeekDayLabel('F'),
                        _WeekDayLabel('S'),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Divider(
                      height: 1,
                      color: scheme.onSurface.withValues(alpha: .12),
                    ),

                    // =========================================
                    // MONTH GRID
                    // =========================================
                    ..._calendarWeeks.map((week) {
                      return _buildWeekRow(week, primaryColor);
                    }),

                    const SizedBox(height: 18),

                    // =========================================
                    // TODAY BUTTON
                    // =========================================
                  ],
                ),
              ),
      ),

      bottomNavigationBar: const MyNavBar(currentIndex: 3),
    );
  }

  // =========================================================
  // WEEK ROW
  // =========================================================

  Widget _buildWeekRow(List<DateTime> week, Color primaryColor) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.onSurface.withValues(alpha: .10)),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: week.map((day) {
          return Expanded(child: _buildDayCell(day, primaryColor));
        }).toList(),
      ),
    );
  }

  // =========================================================
  // DAY CELL
  // =========================================================

  Widget _buildDayCell(DateTime day, Color primaryColor) {
    final theme = Theme.of(context);

    final scheme = theme.colorScheme;

    final isCurrentMonth = _isSameMonth(day, _displayedMonth);

    final isToday = _isSameDate(day, DateTime.now());

    final tasks = _tasksForDate(day);

    const int maxVisibleTasks = 1;

    final visibleTasks = tasks.take(maxVisibleTasks).toList();

    final hiddenCount = tasks.length - visibleTasks.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTap: () {
        if (tasks.isEmpty) {
          _showEmptyDayPopup(day);
        } else {
          _showTasksForDate(day, primaryColor);
        }
      },

      child: Container(
        height: 95,

        padding: const EdgeInsets.fromLTRB(3, 8, 3, 5),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            // DATE
            isToday
                ? Container(
                    width: 30,
                    height: 30,

                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),

                    child: Text(
                      '${day.day}',

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                : SizedBox(
                    height: 36,

                    child: Center(
                      child: Text(
                        '${day.day}',

                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,

                          color: isCurrentMonth
                              ? scheme.onSurface
                              : scheme.onSurface.withValues(alpha: .28),
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 7),

            if (isCurrentMonth && visibleTasks.isNotEmpty)
              ...visibleTasks.map(
                (task) => _buildEventPill(task, day, primaryColor),
              ),

            if (isCurrentMonth && hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '+$hiddenCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: .50),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EVENT PILL
  // =========================================================

  Widget _buildEventPill(Task task, DateTime day, Color primaryColor) {
    final status = _computeStatusForDate(task, day);

    final color = _statusColor(status);

    return GestureDetector(
      onTap: () {
        _showTaskDetails(task, day, primaryColor);
      },

      child: Container(
        width: double.infinity,

        margin: const EdgeInsets.only(bottom: 3),

        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),

        decoration: BoxDecoration(
          color: color.withValues(alpha: .16),

          borderRadius: BorderRadius.circular(6),
        ),

        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,

              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),

            const SizedBox(width: 3),

            Expanded(
              child: Text(
                task.title,

                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DAY TASKS POPUP
  // =========================================================

  void _showTasksForDate(DateTime date, Color primaryColor) {
    final scheme = Theme.of(context).colorScheme;

    final tasks = _tasksForDate(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .72,
          ),

          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),

          decoration: BoxDecoration(
            color: scheme.surface,

            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),

          child: SafeArea(
            top: false,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  width: 42,
                  height: 5,

                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: .15),

                    borderRadius: BorderRadius.circular(50),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  DateFormat('EEEE, MMMM d').format(date),

                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 18),

                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 25),

                    child: Text(
                      'Nothing planned',

                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: .50),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,

                      itemCount: tasks.length,

                      separatorBuilder: (_, _) => const SizedBox(height: 10),

                      itemBuilder: (context, index) {
                        final task = tasks[index];

                        return _taskPreview(task, date, primaryColor);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // TASK PREVIEW
  // =========================================================

  Widget _taskPreview(Task task, DateTime date, Color primaryColor) {
    final scheme = Theme.of(context).colorScheme;

    final status = _computeStatusForDate(task, date);

    final statusColor = _statusColor(status);

    String time = '';

    if (task.startTime != null && task.startTime!.trim().isNotEmpty) {
      time = task.startTime!;
    }

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);

        Future.delayed(const Duration(milliseconds: 120), () {
          if (!mounted) return;

          _showTaskDetails(task, date, primaryColor);
        });
      },

      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,

          borderRadius: BorderRadius.circular(16),
        ),

        child: Row(
          children: [
            Container(
              width: 5,
              height: 52,

              decoration: BoxDecoration(
                color: statusColor,

                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  if (time.isNotEmpty)
                    Text(
                      time,

                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),

                  if (time.isNotEmpty) const SizedBox(height: 4),

                  Text(
                    task.title,

                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _statusLabel(status),

                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              CupertinoIcons.chevron_right,

              size: 17,

              color: scheme.onSurface.withValues(alpha: .35),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // FULL TASK DETAILS POPUP
  // =========================================================

  void _showTaskDetails(Task task, DateTime day, Color primaryColor) {
    final theme = Theme.of(context);

    final scheme = theme.colorScheme;

    final bool isOriginal = theme.extension<AppThemeKey>()?.key == "original";

    const brandColor = Color(0xff050c20);

    final status = _computeStatusForDate(task, day);

    final statusColor = _statusColor(status);

    String time = 'No time set';

    if (task.startTime != null && task.startTime!.trim().isNotEmpty) {
      if (task.endTime != null && task.endTime!.trim().isNotEmpty) {
        time = '${task.startTime} - ${task.endTime}';
      } else {
        time = task.startTime!;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),

          decoration: BoxDecoration(
            color: scheme.surface,

            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),

          child: SafeArea(
            top: false,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,

                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: .15),

                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Container(
                      width: 11,
                      height: 11,

                      margin: const EdgeInsets.only(top: 7, right: 10),

                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),

                    Expanded(
                      child: Text(
                        task.title,

                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,

                          color: isOriginal ? brandColor : scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),

                if (task.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),

                  Text(
                    task.subtitle,

                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,

                      color: scheme.onSurface.withValues(alpha: .65),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                _detailRow(
                  icon: CupertinoIcons.circle_fill,

                  title: 'Status',

                  value: _statusLabel(status),

                  iconColor: statusColor,
                ),

                _detailRow(
                  icon: CupertinoIcons.calendar,

                  title: 'Date',

                  value: DateFormat('EEEE, MMMM d, yyyy').format(day),

                  iconColor: primaryColor,
                ),

                _detailRow(
                  icon: CupertinoIcons.clock,

                  title: 'Time',

                  value: time,

                  iconColor: primaryColor,
                ),

                _detailRow(
                  icon: CupertinoIcons.repeat,

                  title: 'Repeats',

                  value: task.isRecurring == true
                      ? (task.recurrenceType ?? 'Recurring')
                      : 'No',

                  iconColor: primaryColor,
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,

                      foregroundColor: Colors.white,

                      elevation: 0,

                      padding: const EdgeInsets.symmetric(vertical: 15),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // DETAIL ROW
  // =========================================================

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 17),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .10),

              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, size: 18, color: iconColor),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: TextStyle(
                    fontSize: 11,

                    color: scheme.onSurface.withValues(alpha: .50),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,

                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// WEEKDAY LABEL
// ===========================================================

class _WeekDayLabel extends StatelessWidget {
  final String text;

  const _WeekDayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Center(
        child: Text(
          text,

          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,

            color: scheme.onSurface.withValues(alpha: .55),
          ),
        ),
      ),
    );
  }
}
