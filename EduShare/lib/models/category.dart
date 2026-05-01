import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String emoji;
  final int count;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.count,
    required this.color,
  });
}
