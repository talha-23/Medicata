// models/medication.dart
import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final int numberOfTablets; // Number of tablets per dose
  final String dosage; // e.g., "500mg"
  final int numberOfDays; // Number of days to take medication
  final String? notes;
  final DateTime createdAt;
  final bool isActive;
  final String? imagePath; // For registered users to store image path
  final String userId;

  Medication({
    required this.id,
    required this.name,
    required this.numberOfTablets,
    required this.dosage,
    required this.numberOfDays,
    this.notes,
    required this.createdAt,
    this.isActive = true,
    this.imagePath,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'numberOfTablets': numberOfTablets,
      'dosage': dosage,
      'numberOfDays': numberOfDays,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'imagePath': imagePath,
      'userId': userId,
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      numberOfTablets: json['numberOfTablets'],
      dosage: json['dosage'],
      numberOfDays: json['numberOfDays'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
      imagePath: json['imagePath'],
      userId: json['userId'],
    );
  }
}
