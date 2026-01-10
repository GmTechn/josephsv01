class Task {
  final int? id;
  final String status;
  final String title;
  final String subtitle;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final DateTime createdAt;

  Task({
    this.id,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.date,
    this.startTime,
    this.endTime,
    DateTime? createdAt,
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
    );
  }
}
