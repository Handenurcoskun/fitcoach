import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String trainerId;
  final String title;
  final String description;
  final String location;
  final DateTime dateTime;
  final int capacity;
  final List<String> participants;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.trainerId,
    required this.title,
    required this.description,
    required this.location,
    required this.dateTime,
    required this.capacity,
    required this.participants,
    required this.createdAt,
  });

  bool get isFull => capacity > 0 && participants.length >= capacity;
  bool isJoined(String userId) => participants.contains(userId);

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      trainerId: map['trainerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      capacity: map['capacity'] ?? 0,
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'trainerId': trainerId,
        'title': title,
        'description': description,
        'location': location,
        'dateTime': Timestamp.fromDate(dateTime),
        'capacity': capacity,
        'participants': participants,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
