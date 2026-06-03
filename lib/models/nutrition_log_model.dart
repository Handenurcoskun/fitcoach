import 'package:cloud_firestore/cloud_firestore.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExtension on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast: return 'Kahvaltı';
      case MealType.lunch: return 'Öğle';
      case MealType.dinner: return 'Akşam';
      case MealType.snack: return 'Ara Öğün';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast: return '🌅';
      case MealType.lunch: return '☀️';
      case MealType.dinner: return '🌙';
      case MealType.snack: return '🍎';
    }
  }
}

class NutritionLogModel {
  final String id;
  final String memberId;
  final String date;
  final MealType mealType;
  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double amount;
  final DateTime createdAt;

  const NutritionLogModel({
    required this.id,
    required this.memberId,
    required this.date,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.amount,
    required this.createdAt,
  });

  factory NutritionLogModel.fromMap(Map<String, dynamic> map, String id) {
    return NutritionLogModel(
      id: id,
      memberId: map['memberId'] ?? '',
      date: map['date'] ?? '',
      mealType: MealType.values.firstWhere(
        (e) => e.name == map['mealType'],
        orElse: () => MealType.snack,
      ),
      foodName: map['foodName'] ?? '',
      calories: (map['calories'] ?? 0).toDouble(),
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
      amount: (map['amount'] ?? 100).toDouble(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'memberId': memberId,
    'date': date,
    'mealType': mealType.name,
    'foodName': foodName,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'amount': amount,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
