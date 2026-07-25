import 'package:flutter/material.dart';

class PlatformFeature {
  const PlatformFeature({
    this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final String? id;
  final String title;
  final String subtitle;
  final dynamic icon;
  final Color accentColor;
}
