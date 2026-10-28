// User roles — Interface Segregation (ISP) + Liskov Substitution (LSP).
//
// Each capability is a small, focused interface. A role implements only the
// capabilities it really has, so no role is forced to "implement" an action
// it may not perform (no UnsupportedError stubs). Every role is a valid
// substitute for the base UserRole contract (LSP).
//
// The UI checks capabilities with `role is ItemDonor` etc. — the same
// technique as the course's Attendance Role Demonstrator (ISP guide).

/// Base contract every role fulfils (LSP).
abstract class UserRole {
  const UserRole();

  String get id;
  String get label;
  String get description;

  /// Builds the role object from the value stored in users/{uid}.role.
  factory UserRole.fromId(String id) {
    switch (id) {
      case 'donor':
        return const DonorRole();
      case 'requester':
        return const RequesterRole();
      case 'admin':
        return const AdminRole();
      case 'both':
      default:
        return const DonorRequesterRole();
    }
  }

  /// Roles a user may pick for themselves (admin is assigned in the console).
  static const List<UserRole> selectable = [
    DonorRole(),
    RequesterRole(),
    DonorRequesterRole(),
  ];
}

// ---------- capabilities (small, focused interfaces) ----------

/// Can browse and search listings.
abstract class ItemViewer {
  String get browseHint;
}

/// Can create give-away posts and choose requesters.
abstract class ItemDonor {
  String get shareHint;
}

/// Can request items and post needs.
abstract class ItemRequester {
  String get requestHint;
}

/// Can review reports, remove posts and ban users.
abstract class PlatformModerator {
  String get moderationHint;
}

// ---------- concrete roles ----------

class DonorRole extends UserRole implements ItemViewer, ItemDonor {
  const DonorRole();

  @override
  String get id => 'donor';
  @override
  String get label => 'Donor';
  @override
  String get description => 'I want to give away items';
  @override
  String get browseHint => 'Browse what others need';
  @override
  String get shareHint => 'Share an item you no longer use';
}

class RequesterRole extends UserRole implements ItemViewer, ItemRequester {
  const RequesterRole();

  @override
  String get id => 'requester';
  @override
  String get label => 'Requester';
  @override
  String get description => "I'm looking for items";
  @override
  String get browseHint => 'Find items near you';
  @override
  String get requestHint => 'Request an item or post what you need';
}

class DonorRequesterRole extends UserRole
    implements ItemViewer, ItemDonor, ItemRequester {
  const DonorRequesterRole();

  @override
  String get id => 'both';
  @override
  String get label => 'Donor & Requester';
  @override
  String get description => 'I want to give and receive';
  @override
  String get browseHint => 'Browse items and needs';
  @override
  String get shareHint => 'Share an item you no longer use';
  @override
  String get requestHint => 'Request an item or post what you need';
}

class AdminRole extends UserRole
    implements ItemViewer, ItemDonor, ItemRequester, PlatformModerator {
  const AdminRole();

  @override
  String get id => 'admin';
  @override
  String get label => 'Administrator';
  @override
  String get description => 'Moderates the community';
  @override
  String get browseHint => 'Browse all listings';
  @override
  String get shareHint => 'Share an item';
  @override
  String get requestHint => 'Request an item';
  @override
  String get moderationHint => 'Review reports and keep the platform safe';
}
