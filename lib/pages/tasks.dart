// ignore_for_file: deprecated_member_use, prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:josephs_vs_01/components/mynavbar.dart';
import 'package:josephs_vs_01/components/taskscard.dart';
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

  // selection mode (email-like)
  bool _selectionMode = false;
  final Set<int> _selectedTaskIds = {};

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final rows = await _db.getTasks(); // loads all tasks for local user
    if (!mounted) return;
    setState(() => _tasks = rows);
  }

  List<Task> get _filteredTasks {
    if (selectedFilter == "All") return _tasks;
    return _tasks.where((t) => (t.status).trim() == selectedFilter).toList();
  }

  // ----------------------------
  // FILTER BUTTON (✅ INCLUDED)
  // ----------------------------
  Widget _buildFilterButton(String label) {
    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;

          // exit selection mode when switching filters
          _selectionMode = false;
          _selectedTaskIds.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff050c20) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xff050c20),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // APPBAR
  // ----------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false, // ✅ no back arrow
      centerTitle: true,
      title: _selectionMode
          ? Text("${_selectedTaskIds.length} selected")
          : const Text("M Y  T A S K S"),
      leading: _selectionMode
          ? IconButton(
              icon: const Icon(CupertinoIcons.xmark, color: Color(0xff050c20)),
              onPressed: () => _toggleSelectionMode(false),
              tooltip: "Cancel selection",
            )
          : null,
      actions: _selectionMode
          ? [
              IconButton(
                icon: const Icon(CupertinoIcons.trash_fill, color: Colors.red),
                tooltip: "Delete selected",
                onPressed: _selectedTaskIds.isEmpty
                    ? null
                    : _confirmDeleteSelected,
              ),
            ]
          : null,
    );
  }

  // ----------------------------
  // SELECTION MODE
  // ----------------------------
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete tasks?", style: TextStyle(fontSize: 16)),
        content: const Text(
          "Are you sure you want to delete the selected tasks?",
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xff050c20), fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(fontSize: 14, color: Colors.red),
            ),
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

  // ----------------------------
  // STATUS DISPLAY (overdue vs todo)
  // ----------------------------
  String _displayStatus(Task t) {
    final raw = (t.status).trim();

    if (raw == "Done" || raw == "In progress") return raw;

    // For "To do": mark as "Overdue" if date is in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(t.date.year, t.date.month, t.date.day);

    if (taskDay.isBefore(today)) return "Overdue";
    return "To do";
  }

  // ----------------------------
  // BOTTOM SHEET OPTIONS (tap on card)
  // ----------------------------
  void _showTaskOptions(Task task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: Color(0xff050c20),
                ),
                title: const Text("Mark as Done"),
                onTap: () async {
                  Navigator.pop(context);
                  await _db.updateTask(
                    id: task.id!,
                    status: "Done",
                    title: task.title,
                    subtitle: task.subtitle,
                    date: task.date,
                    startTime: task.startTime,
                    endTime: task.endTime,
                  );
                  await _loadTasks();
                },
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.pencil,
                  color: Color(0xff050c20),
                ),
                title: const Text("Edit Task"),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateOrEditTaskDialog(task: task);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------
  // CREATE / EDIT DIALOG
  // - create: only "To do" + "In progress"
  // - edit: allow "To do" + "In progress" + "Done"
  // ----------------------------
  void _showCreateOrEditTaskDialog({Task? task}) {
    final titleController = TextEditingController(text: task?.title ?? "");
    final subtitleController = TextEditingController(
      text: task?.subtitle ?? "",
    );
    DateTime? selectedDate = task?.date;

    final isEdit = task != null;

    String status = task?.status ?? "To do";

    final List<String> statusOptions = isEdit
        ? ["To do", "In progress", "Done"]
        : ["To do", "In progress"]; // ✅ create only 2

    if (!statusOptions.contains(status)) status = statusOptions.first;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(isEdit ? "Edit Task" : "Create Task"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // STATUS
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      items: statusOptions
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setStateDialog(() => status = val ?? status),
                      decoration: InputDecoration(
                        labelText: "Status",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xff050c20).withOpacity(.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff050c20)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // TITLE
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "Title",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xff050c20).withOpacity(.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff050c20)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // SUBTITLE
                    TextField(
                      controller: subtitleController,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: "Subtitle",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xff050c20).withOpacity(.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff050c20)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // DATE PICKER
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? "No date chosen"
                                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                            style: const TextStyle(color: Color(0xff050c20)),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xff050c20),
                                      onPrimary: Colors.white,
                                      onSurface: Color(0xff050c20),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedDate != null) {
                              setStateDialog(() => selectedDate = pickedDate);
                            }
                          },
                          child: const Text(
                            "Select Date",
                            style: TextStyle(color: Color(0xff050c20)),
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
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Color(0xff050c20)),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Color(0xff050c20)),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _db.deleteTask(task.id!);
                        if (mounted) Navigator.pop(context); // close dialog
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
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Color(0xff050c20)),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final sub = subtitleController.text.trim();

                    if (title.isEmpty || sub.isEmpty || selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please fill all fields and pick a date.",
                          ),
                          backgroundColor: Color(0xff050c20),
                          duration: Duration(seconds: 2),
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
                    style: const TextStyle(color: Color(0xff050c20)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // FILTER PILLS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildFilterButton("All"),
                      _buildFilterButton("To do"),
                      _buildFilterButton("In progress"),
                      _buildFilterButton("Done"),
                    ],
                  ),
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
                              : () => _showTaskOptions(task),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            transform: _selectionMode
                                ? Matrix4.translationValues(28, 0, 0)
                                : Matrix4.identity(),
                            child: Stack(
                              children: [
                                MyTaskCard(
                                  status: _displayStatus(task),
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
                                      padding: const EdgeInsets.only(left: 6.0),
                                      child: Center(
                                        child: GestureDetector(
                                          onTap: () =>
                                              _toggleTaskSelection(task.id!),
                                          child: Icon(
                                            isSelected
                                                ? CupertinoIcons
                                                      .check_mark_circled_solid
                                                : CupertinoIcons.circle,
                                            color: isSelected
                                                ? const Color(0xff050c20)
                                                : Colors.grey.shade400,
                                            size: 28,
                                          ),
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
          ? FloatingActionButton(
              tooltip: 'Add a new task',
              onPressed: () => _showCreateOrEditTaskDialog(),
              backgroundColor: const Color(0xff050c20),
              child: const Icon(CupertinoIcons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: const MyNavBar(currentIndex: 1),
    );
  }
}

class _EmptyTasksState extends StatelessWidget {
  const _EmptyTasksState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 6),
          Text(
            "Tap + to create your first task.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
