class Task {
  final int? id;
  final String status;
  final String title;
  final String subtitle;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final DateTime createdAt;
  final bool isRecurring;
  final String? recurrenceType;
  final DateTime? recurrenceEndDate;

  Task({
    this.id,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.date,
    this.startTime,
    this.endTime,
    DateTime? createdAt,
    required this.isRecurring,
    this.recurrenceType,
    this.recurrenceEndDate,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'title': title,
      'subtitle': subtitle,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': createdAt.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceType': recurrenceType,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      status: map['status'],
      title: map['title'],
      subtitle: map['subtitle'],
      date: DateTime.parse(map['date']),
      startTime: map['startTime'],
      endTime: map['endTime'],
      createdAt: DateTime.parse(map['createdAt']),
      isRecurring: (map['isRecurring'] ?? 0) == 1,
      recurrenceType: map['recurrenceType'] as String?,
      recurrenceEndDate: map['recurrenceEndDate'] != null
          ? DateTime.parse(map['recurrenceEndDate'] as String)
          : null,
    );
  }
}
