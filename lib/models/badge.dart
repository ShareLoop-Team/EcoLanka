// Gamification — Achievement Engine (SRP).
//
// Badge tiers from the Shareloop proposal:
//   Bronze 5 · Silver 10 · Gold 25 · Platinum 50+ items donated.
// Computed from users/{uid}.donationCount, so no server code is needed.

import 'package:flutter/material.dart';

class BadgeTier {
  final String id;
  final String title;
  final String level;
  final int threshold;
  final Color color;

  const BadgeTier({
    required this.id,
    required this.title,
    required this.level,
    required this.threshold,
    required this.color,
  });
}

/// A tier as shown on screen, with whether this user has earned it.
class BadgeInfo {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool earned;
  final Color color;

  const BadgeInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.earned,
    this.color = const Color(0xFFF59E0B),
  });
}

class AchievementEngine {
  AchievementEngine._();

  static const List<BadgeTier> tiers = [
    BadgeTier(
      id: 'bronze',
      title: 'Bronze',
      level: 'New Contributor',
      threshold: 5,
      color: Color(0xFFCD7F32),
    ),
    BadgeTier(
      id: 'silver',
      title: 'Silver',
      level: 'Active Contributor',
      threshold: 10,
      color: Color(0xFF9E9E9E),
    ),
    BadgeTier(
      id: 'gold',
      title: 'Gold',
      level: 'Trusted Contributor',
      threshold: 25,
      color: Color(0xFFF59E0B),
    ),
    BadgeTier(
      id: 'platinum',
      title: 'Platinum',
      level: 'Community Champion',
      threshold: 50,
      color: Color(0xFF5C6BC0),
    ),
  ];

  /// Highest tier reached, or null below 5 donations.
  static BadgeTier? currentTier(int donations) {
    BadgeTier? result;
    for (final t in tiers) {
      if (donations >= t.threshold) result = t;
    }
    return result;
  }

  /// Next tier to aim for, or null once Platinum is reached.
  static BadgeTier? nextTier(int donations) {
    for (final t in tiers) {
      if (donations < t.threshold) return t;
    }
    return null;
  }

  /// 0.0–1.0 progress from the current tier to the next one.
  static double progressToNext(int donations) {
    final next = nextTier(donations);
    if (next == null) return 1;
    final start = currentTier(donations)?.threshold ?? 0;
    return ((donations - start) / (next.threshold - start)).clamp(0.0, 1.0);
  }

  /// 10 points per completed donation, 2 per request sent.
  static int ecoPoints({required int donations, required int requests}) =>
      donations * 10 + requests * 2;

  /// All tiers with earned / not earned for this user.
  static List<BadgeInfo> badges(int donations) => [
        for (final t in tiers)
          BadgeInfo(
            id: t.id,
            title: t.title,
            description: '${t.threshold}${t.id == 'platinum' ? '+' : ''} donations · ${t.level}',
            icon: Icons.workspace_premium,
            earned: donations >= t.threshold,
            color: t.color,
          ),
      ];
}
