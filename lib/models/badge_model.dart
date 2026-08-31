import 'package:flutter/material.dart';

class BadgeModel {
  final String id;
  final String titleEn;
  final String titleUr;
  final String descriptionEn;
  final String descriptionUr;
  final IconData icon;
  final LinearGradient gradient;
  final bool isUnlocked;
  final int requiredCount;
  final int currentCount;

  const BadgeModel({
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.icon,
    required this.gradient,
    this.isUnlocked = false,
    this.requiredCount = 1,
    this.currentCount = 0,
  });
}
