// users/{uid} — see docs/SCHEMA.md

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
  });

  bool get canDonate => role == 'donor' || role == 'both' || role == 'admin';
  bool get canRequest => role == 'requester' || role == 'both' || role == 'admin';

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
      };
}
