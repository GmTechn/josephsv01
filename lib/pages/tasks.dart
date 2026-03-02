// ignore_for_file: deprecated_member_use, prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:josephs_vs_01/components/mynavbar.dart';
import 'package:josephs_vs_01/components/taskscard.dart';
import 'package:josephs_vs_01/main.dart';
import 'package:josephs_vs_01/management/database.dart';
import 'package:josephs_vs_01/models/tasks.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, this.initialFilter = "All"});
  final String initialFilter;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final DatabaseManager _db = DatabaseManager();

  late String selectedFilter;
  List<Task> _tasks = [];

  bool _selectionMode = false;
  final Set<int> _selectedTaskIds = {};

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final rows = await _db.getTasks();
    if (!mounted) return;
    setState(() => _tasks = rows);
  }

  List<Task> get _filteredTasks {
    if (selectedFilter == "All") return _tasks;
    return _tasks.where((t) => (t.status).trim() == selectedFilter).toList();
  }

  bool _isOriginal(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.primary == const Color(0xff050c20) &&
        Theme.of(context).brightness == Brightness.light;
  }

  // ---------------- FILTER BUTTON ----------------
  Widget _buildFilterButton(String label) {
    final scheme = Theme.of(context).colorScheme;
    final isOriginal =
        Theme.of(context).extension<AppThemeKey>()?.key == "original";

    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
          _selectionMode = false;
          _selectedTaskIds.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isOriginal ? const Color(0xFF050C20) : scheme.primary)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : scheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------- APPBAR ----------------
  PreferredSizeWidget _buildAppBar() {
    final scheme = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: _selectionMode
          ? Text("${_selectedTaskIds.length} selected")
          : const Text("M Y  T A S K S"),
      leading: _selectionMode
          ? IconButton(
              icon: Icon(CupertinoIcons.xmark, color: scheme.primary),
              onPressed: () => _toggleSelectionMode(false),
            )
          : null,
      actions: _selectionMode
          ? [
              IconButton(
                icon: const Icon(CupertinoIcons.trash_fill, color: Colors.red),
                onPressed: _selectedTaskIds.isEmpty
                    ? null
                    : _confirmDeleteSelected,
              ),
            ]
          : null,
    );
  }

  void _toggleSelectionMode(bool enable) {
    setState(() {
      _selectionMode = enable;
      if (!enable) _selectedTaskIds.clear();
    });
  }

  void _toggleTaskSelection(int id) {
    setState(() {
      if (_selectedTaskIds.contains(id)) {
        _selectedTaskIds.remove(id);
      } else {
        _selectedTaskIds.add(id);
      }
    });
  }

  Future<void> _confirmDeleteSelected() async {
    final scheme = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete tasks?"),
        content: const Text(
          "Are you sure you want to delete the selected tasks?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: scheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (final id in _selectedTaskIds) {
      await _db.deleteTask(id);
    }

    _toggleSelectionMode(false);
    await _loadTasks();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOriginal = _isOriginal(context);

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 20),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Wrap(
                spacing: 10,
                children: [
                  _buildFilterButton("All"),
                  _buildFilterButton("To do"),
                  _buildFilterButton("In progress"),
                  _buildFilterButton("Done"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _filteredTasks.isEmpty
                ? const Center(child: _EmptyTasksState())
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        final isSelected = _selectedTaskIds.contains(
                          task.id ?? -1,
                        );

                        return GestureDetector(
                          onLongPress: () => _toggleSelectionMode(true),
                          onTap: _selectionMode
                              ? () => _toggleTaskSelection(task.id!)
                              : () => _showCreateOrEditTaskDialog(task: task),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            transform: _selectionMode
                                ? Matrix4.translationValues(28, 0, 0)
                                : Matrix4.identity(),
                            child: Stack(
                              children: [
                                MyTaskCard(
                                  status: task.status,
                                  title: task.title,
                                  subject: task.subtitle,
                                  date: task.date,
                                ),
                                if (_selectionMode)
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Center(
                                        child: Icon(
                                          isSelected
                                              ? CupertinoIcons
                                                    .check_mark_circled_solid
                                              : CupertinoIcons.circle,
                                          color: isSelected
                                              ? (isOriginal
                                                    ? const Color(0xff050c20)
                                                    : scheme.primary)
                                              : scheme.onSurface.withOpacity(
                                                  .4,
                                                ),
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: !_selectionMode
          ? Builder(
              builder: (context) {
                final scheme = Theme.of(context).colorScheme;
                final isOriginal =
                    Theme.of(context).extension<AppThemeKey>()?.key ==
                    "original";

                return FloatingActionButton(
                  tooltip: 'Add a new task',
                  onPressed: () => _showCreateOrEditTaskDialog(),
                  backgroundColor: isOriginal
                      ? const Color(0xFF050C20)
                      : scheme.primary,
                  child: Icon(CupertinoIcons.add, color: Colors.white),
                );
              },
            )
          : null,
      bottomNavigationBar: const MyNavBar(currentIndex: 1),
    );
  }

  void _showCreateOrEditTaskDialog({Task? task}) {
    final parentScheme = Theme.of(context).colorScheme;

    final bool isOriginal =
        parentScheme.primary == const Color(0xff050c20) &&
        Theme.of(context).brightness == Brightness.light;

    final Color primaryColor = isOriginal
        ? const Color(0xff050c20)
        : parentScheme.primary;

    final titleController = TextEditingController(text: task?.title ?? "");
    final subtitleController = TextEditingController(
      text: task?.subtitle ?? "",
    );

    DateTime? selectedDate = task?.date;
    final bool isEdit = task != null;

    String status = task?.status ?? "To do";

    final List<String> statusOptions = isEdit
        ? ["To do", "In progress", "Done"]
        : ["To do", "In progress"];

    if (!statusOptions.contains(status)) {
      status = statusOptions.first;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Theme(
          data: Theme.of(dialogContext).copyWith(
            colorScheme: Theme.of(dialogContext).colorScheme.copyWith(
              primary: primaryColor,
              secondary: primaryColor,
            ),
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor.withOpacity(.5)),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              final scheme = Theme.of(context).colorScheme;

              return AlertDialog(
                backgroundColor: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(isEdit ? "Edit Task" : "Create Task"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        items: statusOptions
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setStateDialog(() => status = val ?? status),
                        decoration: const InputDecoration(labelText: "Status"),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(hintText: "Title"),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: subtitleController,
                        maxLines: 3,
                        decoration: const InputDecoration(hintText: "Subtitle"),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? "No date chosen"
                                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                              style: TextStyle(color: scheme.onSurface),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );

                              if (pickedDate != null) {
                                setStateDialog(() => selectedDate = pickedDate);
                              }
                            },
                            child: Text(
                              "Select Date",
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (isEdit)
                    TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete task?"),
                            content: const Text(
                              "Are you sure you want to delete this task?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(color: primaryColor),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _db.deleteTask(task.id!);
                          if (mounted) Navigator.pop(context);
                          await _loadTasks();
                        }
                      },
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final sub = subtitleController.text.trim();

                      if (title.isEmpty ||
                          sub.isEmpty ||
                          selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "Please fill all fields and pick a date.",
                            ),
                            backgroundColor: primaryColor,
                          ),
                        );
                        return;
                      }

                      if (!isEdit) {
                        await _db.createTask(
                          title: title,
                          subtitle: sub,
                          date: selectedDate!,
                          status: status,
                        );
                      } else {
                        await _db.updateTask(
                          id: task.id!,
                          status: status,
                          title: title,
                          subtitle: sub,
                          date: selectedDate!,
                          startTime: task.startTime,
                          endTime: task.endTime,
                        );
                      }

                      Navigator.pop(context);
                      await _loadTasks();
                    },
                    child: Text(
                      isEdit ? "Save" : "Add",
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyTasksState extends StatelessWidget {
  const _EmptyTasksState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          Text(
            "Tap + to create your first task.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: scheme.onSurface.withOpacity(.6),
            ),
          ),
        ],
      ),
    );
  }
}
