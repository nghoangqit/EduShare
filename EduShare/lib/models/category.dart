import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final int count;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.count,
    required this.color,
  });
}
