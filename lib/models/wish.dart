import 'package:flutter/material.dart';

enum WishPriority { low, medium, high }

class Wish {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final WishPriority priority;
  final bool isFavorite;
  final DateTime createdAt;
  final String category;

  Wish({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.priority = WishPriority.medium,
    this.isFavorite = false,
    required this.createdAt,
    this.category = 'General',
  });

  factory Wish.fromJson(Map<String, dynamic> json) {
    return Wish(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      price: json['price'].toDouble(),
      priority: WishPriority.values.firstWhere(
        (e) => e.toString() == 'WishPriority.${json['priority']}',
        orElse: () => WishPriority.medium,
      ),
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      category: json['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'priority': priority.toString().split('.').last,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
    };
  }

  String get priorityText {
    switch (priority) {
      case WishPriority.low:
        return 'Low Priority';
      case WishPriority.medium:
        return 'Medium Priority';
      case WishPriority.high:
        return 'High Priority';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case WishPriority.low:
        return Colors.blue;
      case WishPriority.medium:
        return Colors.orange;
      case WishPriority.high:
        return Colors.red;
    }
  }
}
