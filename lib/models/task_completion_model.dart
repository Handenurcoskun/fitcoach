import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCompletionModel {
  final String id;
  final String taskId;
  final String memberId;
  final String date; // format: YYYY-MM-DD
  final bool isCompleted;
  final String? note;
  final DateTime? completedAt;

  const TaskCompletionModel({
    required this.id,
    required this.taskId,
    required this.memberId,
    required this.date,
    required this.isCompleted,
    this.note,
    this.completedAt,
  });

  factory TaskCompletionModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskCompletionModel(
      id: id,
      taskId: map['taskId'] ?? '',
      memberId: map['memberId'] ?? '',
      date: map['date'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      note: map['note'],
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'memberId': memberId,
      'date': date,
      'isCompleted': isCompleted,
      'note': note,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  TaskCompletionModel copyWith({
    bool? isCompleted,
    String? note,
    DateTime? completedAt,
  }) {
    return TaskCompletionModel(
      id: id,
      taskId: taskId,
      memberId: memberId,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
      note: note ?? this.note,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
