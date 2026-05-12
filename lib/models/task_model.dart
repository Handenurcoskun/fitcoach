import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskType {
  water,
  exercise,
  gratitude,
  nutrition,
  meditation,
  sleep,
  steps,
  custom,
}

extension TaskTypeExtension on TaskType {
  String get label {
    switch (this) {
      case TaskType.water:
        return 'Su İçme';
      case TaskType.exercise:
        return 'Spor';
      case TaskType.gratitude:
        return 'Şükür Defteri';
      case TaskType.nutrition:
        return 'Beslenme';
      case TaskType.meditation:
        return 'Meditasyon';
      case TaskType.sleep:
        return 'Uyku';
      case TaskType.steps:
        return 'Adım Sayısı';
      case TaskType.custom:
        return 'Özel Görev';
    }
  }

  String get emoji {
    switch (this) {
      case TaskType.water:
        return '💧';
      case TaskType.exercise:
        return '🏋️';
      case TaskType.gratitude:
        return '📔';
      case TaskType.nutrition:
        return '🥗';
      case TaskType.meditation:
        return '🧘';
      case TaskType.sleep:
        return '😴';
      case TaskType.steps:
        return '👟';
      case TaskType.custom:
        return '✏️';
    }
  }

  String get name {
    return toString().split('.').last;
  }
}

TaskType taskTypeFromString(String value) {
  return TaskType.values.firstWhere(
    (e) => e.toString().split('.').last == value,
    orElse: () => TaskType.custom,
  );
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskType type;
  final String trainerId;
  final List<String> assignedMemberIds;
  final bool isActive;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.trainerId,
    required this.assignedMemberIds,
    required this.isActive,
    required this.createdAt,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: taskTypeFromString(map['type'] ?? 'custom'),
      trainerId: map['trainerId'] ?? '',
      assignedMemberIds: List<String>.from(map['assignedMemberIds'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'trainerId': trainerId,
      'assignedMemberIds': assignedMemberIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    TaskType? type,
    List<String>? assignedMemberIds,
    bool? isActive,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      trainerId: trainerId,
      assignedMemberIds: assignedMemberIds ?? this.assignedMemberIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
