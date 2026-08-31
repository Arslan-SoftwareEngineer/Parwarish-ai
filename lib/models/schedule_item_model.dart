import 'package:flutter/material.dart';

class ScheduleItemModel {
  final String id;
  final String titleEn;
  final String titleUr;
  final String time;
  final IconData icon;
  final LinearGradient gradient;
  final bool isCompleted;

  const ScheduleItemModel({
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.time,
    required this.icon,
    required this.gradient,
    this.isCompleted = false,
  });

  ScheduleItemModel copyWith({
    String? id,
    String? titleEn,
    String? titleUr,
    String? time,
    IconData? icon,
    LinearGradient? gradient,
    bool? isCompleted,
  }) {
    return ScheduleItemModel(
      id: id ?? this.id,
      titleEn: titleEn ?? this.titleEn,
      titleUr: titleUr ?? this.titleUr,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      gradient: gradient ?? this.gradient,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
