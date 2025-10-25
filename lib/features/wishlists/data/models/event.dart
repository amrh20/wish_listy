import 'package:flutter/material.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String icon;
  final Color iconColor;
  final List<String> participants;
  final int daysUntil;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    required this.iconColor,
    required this.participants,
  }) : daysUntil = DateTime.now().difference(date).inDays;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      icon: json['icon'],
      iconColor: Color(json['iconColor']),
      participants: List<String>.from(json['participants']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'icon': icon,
      'iconColor': iconColor.value,
      'participants': participants,
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
