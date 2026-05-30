import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementModel {
  final String id;
  final String memberId;
  final DateTime date;
  final String gender; // 'E' or 'K'
  final double weightKg;
  final double heightCm;
  final double neckCm;
  final double waistCm;
  final double? hipCm;
  final String? note;

  const MeasurementModel({
    required this.id,
    required this.memberId,
    required this.date,
    required this.gender,
    required this.weightKg,
    required this.heightCm,
    required this.neckCm,
    required this.waistCm,
    this.hipCm,
    this.note,
  });

  double? get bodyFatPercent {
    try {
      if (gender == 'K') {
        final hip = hipCm ?? 0;
        if (hip <= 0 || waistCm + hip - neckCm <= 0) return null;
        final val = 163.205 * log(waistCm + hip - neckCm) / ln10
            - 97.684 * log(heightCm) / ln10
            - 78.387;
        return val.clamp(1.0, 60.0);
      } else {
        if (waistCm - neckCm <= 0) return null;
        final val = 86.010 * log(waistCm - neckCm) / ln10
            - 70.041 * log(heightCm) / ln10
            + 36.76;
        return val.clamp(1.0, 60.0);
      }
    } catch (_) {
      return null;
    }
  }

  factory MeasurementModel.fromMap(Map<String, dynamic> map, String id) {
    return MeasurementModel(
      id: id,
      memberId: map['memberId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      gender: map['gender'] ?? 'E',
      weightKg: (map['weightKg'] ?? 0).toDouble(),
      heightCm: (map['heightCm'] ?? 0).toDouble(),
      neckCm: (map['neckCm'] ?? 0).toDouble(),
      waistCm: (map['waistCm'] ?? 0).toDouble(),
      hipCm: map['hipCm'] != null ? (map['hipCm'] as num).toDouble() : null,
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() => {
    'memberId': memberId,
    'date': Timestamp.fromDate(date),
    'gender': gender,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'neckCm': neckCm,
    'waistCm': waistCm,
    if (hipCm != null) 'hipCm': hipCm,
    if (note != null) 'note': note,
  };
}
