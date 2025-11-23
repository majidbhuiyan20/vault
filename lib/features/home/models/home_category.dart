// lib/features/home/models/home_category.dart
import 'package:flutter/material.dart';

class HomeCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final int count;
  final String type;
  final DateTime createdAt;
  final bool isCustom;

  HomeCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.count,
    required this.type,
    required this.createdAt,
    this.isCustom = false,
  });

  // Convert to Map for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon.codePoint,
      'color': color.value,
      'gradient': gradient.map((color) => color.value).toList(),
      'count': count,
      'type': type,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isCustom': isCustom,
    };
  }

  // Create from Map for local storage
  factory HomeCategory.fromJson(Map<String, dynamic> json) {
    return HomeCategory(
      id: json['id'],
      title: json['title'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      gradient: (json['gradient'] as List)
          .map((colorValue) => Color(colorValue))
          .toList(),
      count: json['count'],
      type: json['type'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      isCustom: json['isCustom'] ?? false,
    );
  }

  // Copy with method for immutability
  HomeCategory copyWith({
    String? id,
    String? title,
    IconData? icon,
    Color? color,
    List<Color>? gradient,
    int? count,
    String? type,
    DateTime? createdAt,
    bool? isCustom,
  }) {
    return HomeCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      count: count ?? this.count,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
