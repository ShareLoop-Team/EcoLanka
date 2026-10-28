// users/{uid} — see docs/SCHEMA.md

import 'user_role.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final String role; // donor | requester | both | admin
  final String language; // en | si | ta
  final String district;
  final int points;
  final List<String> badges;
  final int donationCount;
  final int requestCount;
  final double rating;
  final bool isBanned;

  /// Monthly leaderboard: "YYYY-M" (UTC) of the last donation + count that month.
  final String? monthKey;
  final int monthDonations;

  const AppUser({
    required this.uid,
    required this.displayName,
    this.phone,
    this.email,
    this.photoUrl,
    required this.role,
    required this.language,
    required this.district,
    this.points = 0,
    this.badges = const [],
    this.donationCount = 0,
    this.requestCount = 0,
    this.rating = 0,
    this.isBanned = false,
    this.monthKey,
    this.monthDonations = 0,
  });

  /// Role object with its capabilities (see user_role.dart — ISP / LSP).
  UserRole get roleType => UserRole.fromId(role);

  bool get canDonate => !isBanned && roleType is ItemDonor;
  bool get canRequest => !isBanned && roleType is ItemRequester;
  bool get isModerator => roleType is PlatformModerator;

  /// Donations made in [monthKey] (0 if the stored month is an older one).
  int donationsInMonth(String currentMonthKey) =>
      monthKey == currentMonthKey ? monthDonations : 0;

  /// "2026-10" style key for the current UTC month (matches the rules).
  static String monthKeyFor(DateTime time) {
    final utc = time.toUtc();
    return '${utc.year}-${utc.month}';
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        displayName: m['displayName'] as String? ?? '',
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        photoUrl: m['photoUrl'] as String?,
        role: m['role'] as String? ?? 'both',
        language: m['language'] as String? ?? 'en',
        district: m['district'] as String? ?? 'Colombo',
        points: (m['points'] as num?)?.toInt() ?? 0,
        badges: List<String>.from(m['badges'] as List? ?? const []),
        donationCount: (m['donationCount'] as num?)?.toInt() ?? 0,
        requestCount: (m['requestCount'] as num?)?.toInt() ?? 0,
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        isBanned: m['isBanned'] as bool? ?? false,
        monthKey: m['monthKey'] as String?,
        monthDonations: (m['monthDonations'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'phone': phone,
        'email': email,
        'photoUrl': photoUrl,
        'role': role,
        'language': language,
        'district': district,
        'points': points,
        'badges': badges,
        'donationCount': donationCount,
        'requestCount': requestCount,
        'rating': rating,
        'isBanned': isBanned,
        'monthKey': monthKey,
        'monthDonations': monthDonations,
      };
}
