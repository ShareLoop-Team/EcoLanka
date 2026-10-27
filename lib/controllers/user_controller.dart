// UserController — profiles, leaderboards, profile photo, "near me" (MVC).

import 'package:image_picker/image_picker.dart';

import '../models/user.dart';
import '../repositories/repositories.dart';
import '../utils/district_locator.dart';

class UserController {
  UserController({
    required UserRepository users,
    required AuthRepository auth,
    required ImageStorage images,
    required LocationProvider location,
  })  : _users = users,
        _auth = auth,
        _images = images,
        _location = location;

  final UserRepository _users;
  final AuthRepository _auth;
  final ImageStorage _images;
  final LocationProvider _location;

  String? get currentUid => _auth.currentUid;

  // ---------- profile ----------

  /// The signed-in user's profile, or null if they haven't completed setup.
  Future<AppUser?> getCurrentUserProfile() async {
    final uid = _auth.currentUid;
    if (uid == null) return null;
    return _users.getUser(uid);
  }

  Stream<AppUser?> watchUser(String uid) => _users.watchUser(uid);

  Stream<AppUser?> watchCurrentUser() {
    final uid = _auth.currentUid;
    if (uid == null) return Stream.value(null);
    return _users.watchUser(uid);
  }

  /// First-time profile (profile setup screen).
  Future<void> createUserProfile({
    required String displayName,
    required String district,
    required String role, // donor | requester | both
    required String language, // en | si | ta
  }) {
    final uid = _auth.currentUid;
    if (uid == null) throw StateError('Not signed in.');
    final profile = AppUser(
      uid: uid,
      displayName: displayName.trim(),
      phone: _auth.currentPhone,
      role: role,
      language: language,
      district: district,
    );
    return _users.createUser(uid, profile.toMap());
  }

  /// Editable fields only: displayName, district, language, photoUrl, role.
  Future<void> updateProfile(Map<String, dynamic> fields) {
    final uid = _auth.currentUid;
    if (uid == null) throw StateError('Not signed in.');
    return _users.updateUser(uid, fields);
  }

  /// Admin moderation.
  Future<void> setBanned(String uid, bool banned) =>
      _users.updateUser(uid, {'isBanned': banned});

  // ---------- leaderboards ----------

  static String get currentMonthKey => AppUser.monthKeyFor(DateTime.now());

  Stream<List<AppUser>> leaderboard() => _users
      .topDonors()
      .map((list) => list.where((u) => u.donationCount > 0).toList());

  /// Monthly leaderboard (Shareloop docs §3.2): donations this month.
  Stream<List<AppUser>> monthlyLeaderboard() {
    final key = currentMonthKey;
    return _users.donorsOfMonth(key).map((list) {
      final ranked = list.where((u) => u.donationsInMonth(key) > 0).toList()
        ..sort((a, b) => b.donationsInMonth(key).compareTo(a.donationsInMonth(key)));
      return ranked.take(20).toList();
    });
  }

  // ---------- profile photo ----------

  bool get photoUploadsEnabled => _images.isConfigured;

  Future<XFile?> pickPhoto() => _images.pickOne();

  Future<String> uploadProfilePhoto(XFile file) =>
      _images.upload(file, folder: 'users/${_auth.currentUid}');

  // ---------- location ----------

  /// Uses GPS to find the user's nearest district (Geo engine, SRP).
  Future<String> detectNearestDistrict() async {
    final point = await _location.currentPosition();
    return DistrictLocator.nearestDistrict(point);
  }
}
