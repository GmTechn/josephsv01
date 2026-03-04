// ignore_for_file: deprecated_member_use, prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:josephs_vs_01/components/mynavbar.dart';
import 'package:josephs_vs_01/components/taskscard.dart';
import 'package:josephs_vs_01/main.dart';
import 'package:josephs_vs_01/management/database.dart';
import 'package:josephs_vs_01/management/subscription_service.dart';
import 'package:josephs_vs_01/models/tasks.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

  //vars for speech to text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  //microphone key
  final GlobalKey _micKey = GlobalKey();

  //subscription variable
  final SubscriptionService subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
    _loadTasks();
    _speech = stt.SpeechToText();
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
        title: const Text(
          "Delete tasks?",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete the selected tasks?",
          style: TextStyle(fontSize: 14),
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

  //-------- Listening to the speech to change to text ------//
  //to know if we are still listening or not ---//

  Future<void> _toggleListening(TextEditingController controller) async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          onResult: (result) {
            setState(() {
              controller.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  //------- Speech to Text subcription -----//
  Future<bool> _canUseVoiceFeature() async {
    return subscriptionService.isSubscribed;
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

  // ----------------------------
  // BOTTOM SHEET OPTIONS (tap on card)
  // ----------------------------
  void _showTaskOptions(Task task) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: scheme.primary,
                ),
                title: Text(
                  "Mark as Done",
                  style: TextStyle(color: scheme.onSurface),
                ),
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
                leading: Icon(CupertinoIcons.pencil, color: scheme.primary),
                title: Text(
                  "Edit Task",
                  style: TextStyle(color: scheme.onSurface),
                ),
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

  //----- Show start trial dialog ----///
  // void _showUpgradeDialog() {
  //   final scheme = Theme.of(context).colorScheme;
  //   final isOriginal =
  //       Theme.of(context).extension<AppThemeKey>()?.key == "original";

  //   final textColor = isOriginal ? const Color(0xff050c20) : scheme.onSurface;

  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       backgroundColor: scheme.surface,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: Text(
  //         "Unlock Voice",
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.bold,
  //           color: textColor,
  //         ),
  //       ),
  //       content: Text(
  //         "Start your 7-day free trial.\n\nThen \$2.99/month.",
  //         style: TextStyle(fontSize: 14, color: textColor),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text("Not now", style: TextStyle(color: textColor)),
  //         ),
  //         TextButton(
  //           onPressed: () async {
  //             Navigator.pop(context);
  //             await subscriptionService.buy();
  //           },
  //           child: Text(
  //             "Start Trial",
  //             style: TextStyle(
  //               fontWeight: FontWeight.bold,
  //               color: isOriginal ? const Color(0xff050c20) : scheme.primary,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  //------ Show coming soon dialog ----//
  void _showComingSoonDialog() {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Voice Feature",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          "This feature is coming in the next update. Stay tuned!",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  //----- show tooltip ----//
  void _showDoneTooltip(BuildContext context, GlobalKey key) {
    final overlay = Overlay.of(context);
    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + size.width / 2 - 40,
        top: position.dy - 40,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Done",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 900), () {
      entry.remove();
    });
  }

  //----- Add create or edit task ----///
  void _showCreateOrEditTaskDialog({Task? task}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bool isOriginal = theme.extension<AppThemeKey>()?.key == "original";

    final Color primaryColor = isOriginal
        ? const Color(0xff050c20)
        : scheme.primary;

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
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEdit ? "Edit Task" : "Create Task",
                style: TextStyle(color: scheme.onSurface),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // STATUS
                    DropdownButtonFormField<String>(
                      value: status,
                      dropdownColor: scheme.surface,
                      style: TextStyle(color: scheme.onSurface),
                      items: statusOptions
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          status = val ?? status;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Status",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryColor.withOpacity(.4),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TITLE
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: scheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Title",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryColor.withOpacity(.4),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SUBTITLE
                    TextField(
                      controller: subtitleController,
                      maxLines: 3,
                      style: TextStyle(color: scheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Subtitle (optional)",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryColor.withOpacity(.4),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // DATE + MIC
                    Row(
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (pickedDate != null) {
                              setDialogState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: Text(
                            selectedDate == null
                                ? "Select date"
                                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const Spacer(),

                        InkWell(
                          key: _micKey,
                          customBorder: const CircleBorder(),
                          onTap: () async {
                            final allowed = await _canUseVoiceFeature();
                            if (!allowed) {
                              _showComingSoonDialog();
                              return;
                            }

                            final wasListening = _isListening;

                            await _toggleListening(subtitleController);

                            setDialogState(() {});

                            if (wasListening) {
                              _showDoneTooltip(context, _micKey);
                            }
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.mic_fill,
                                size: 30,
                                color: scheme.primary,
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "Soon",
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // AnimatedContainer(
                          //   duration: const Duration(milliseconds: 200),
                          //   padding: const EdgeInsets.all(14),
                          //   decoration: BoxDecoration(
                          //     shape: BoxShape.circle,
                          //     color: _isListening
                          //         ? Colors.red.withOpacity(0.12)
                          //         : primaryColor.withOpacity(0.10),
                          //   ),
                          //   child: AnimatedSwitcher(
                          //     duration: const Duration(milliseconds: 150),
                          //     child: Icon(
                          //       _isListening
                          //           ? CupertinoIcons.stop_fill
                          //           : CupertinoIcons.mic_fill,
                          //       key: ValueKey(_isListening),
                          //       size: 20,
                          //       color: _isListening ? Colors.red : primaryColor,
                          //     ),
                          //   ),
                          // ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_isListening) {
                      _speech.stop();
                      _isListening = false;
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: scheme.onSurface),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();

                    if (title.isEmpty || selectedDate == null) {
                      showDialog(
                        context: context,
                        builder: (_) {
                          final scheme = Theme.of(context).colorScheme;
                          final isOriginal =
                              Theme.of(context).extension<AppThemeKey>()?.key ==
                              "original";

                          final textColor = isOriginal
                              ? const Color(0xff050c20)
                              : scheme.onSurface;

                          return AlertDialog(
                            backgroundColor: scheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              "Missing information",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            content: Text(
                              "Please enter a title and select a date before continuing.",
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "OK",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isOriginal
                                        ? const Color(0xff050c20)
                                        : scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      return;
                    }

                    if (_isListening) {
                      _speech.stop();
                      _isListening = false;
                    }

                    if (!isEdit) {
                      await _db.createTask(
                        title: title,
                        subtitle: subtitleController.text.trim(),
                        date: selectedDate!,
                        status: status,
                      );
                    } else {
                      await _db.updateTask(
                        id: task.id!,
                        status: status,
                        title: title,
                        subtitle: subtitleController.text.trim(),
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
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
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
