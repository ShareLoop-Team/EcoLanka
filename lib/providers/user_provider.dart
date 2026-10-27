import 'package:flutter/foundation.dart';

import '../models/user.dart';

/// App-wide state for the signed-in user.
///
/// [profile] is kept in sync with users/{uid} by the home shell
/// (HomeScreen listens to Dependencies.users.watchCurrentUser()).
class UserProvider extends ChangeNotifier {
  // Default location/district
  String _district = 'Colombo';
  AppUser? _profile;

  /// Get the currently selected district
  String get district => _district;

  /// The signed-in user's profile (null until loaded / signed out).
  AppUser? get profile => _profile;

  bool get canDonate => _profile?.canDonate ?? true;
  bool get canRequest => _profile?.canRequest ?? true;
  bool get isAdmin => _profile?.role == 'admin';

  /// Update the district and notify all listeners
  void updateDistrict(String newDistrict) {
    _district = newDistrict;
    notifyListeners();
  }

  void setProfile(AppUser? profile) {
    _profile = profile;
    if (profile != null) _district = profile.district;
    notifyListeners();
  }

  void clear() {
    _profile = null;
    _district = 'Colombo';
    notifyListeners();
  }
}
