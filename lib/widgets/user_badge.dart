import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/badge.dart';

class BadgeTile extends StatelessWidget {
  final BadgeInfo badge;

  const BadgeTile({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = badge.earned ? badge.color : Colors.grey.shade400;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badge.earned ? const Color(0xFFFFF8E1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(badge.icon, color: color, size: 34),
          const SizedBox(height: 8),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: badge.earned ? AppColors.textPrimary : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
