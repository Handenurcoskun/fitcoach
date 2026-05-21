import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { trainer, member }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? trainerId;
  final String? inviteCode; // Sadece trainer için
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.trainerId,
    this.inviteCode,
    required this.createdAt,
  });

  bool get isTrainer => role == UserRole.trainer;

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] == 'trainer' ? UserRole.trainer : UserRole.member,
      trainerId: map['trainerId'],
      inviteCode: map['inviteCode'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role == UserRole.trainer ? 'trainer' : 'member',
      'trainerId': trainerId,
      if (inviteCode != null) 'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? trainerId,
    String? inviteCode,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      trainerId: trainerId ?? this.trainerId,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt,
    );
  }
}
