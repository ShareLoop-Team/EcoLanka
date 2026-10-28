// Repository abstractions — Dependency Inversion (DIP).
//
// Controllers (high-level business logic) depend ONLY on these interfaces.
// The Laravel API / GPS implementations live in lib/services/ and
// are plugged in once, in lib/config/dependencies.dart. Tests can plug in
// fakes instead (see test/controller_test.dart).
//
//   View  →  Controller  →  Repository (this file)  ←  Service (REST API)

import 'package:image_picker/image_picker.dart';

import '../models/app_notification.dart';
import '../models/item.dart';
import '../models/need.dart';
import '../models/rating.dart';
import '../models/report.dart';
import '../models/request.dart';
import '../models/user.dart';
import '../utils/district_locator.dart';

abstract class AuthRepository {
  String? get currentUid;
  String? get currentPhone;

  /// Sends an SMS code. Returns true if the device was verified instantly.
  Future<bool> sendCode(String phoneE164);
  Future<void> verifyCode(String smsCode);
  Future<void> signOut();

  String messageFor(Object error);
  bool isInvalidCode(Object error);
}

abstract class UserRepository {
  Future<AppUser?> getUser(String uid);
  Stream<AppUser?> watchUser(String uid);
  Future<void> createUser(String uid, Map<String, dynamic> data);
  Future<void> updateUser(String uid, Map<String, dynamic> fields);
  Stream<List<AppUser>> topDonors({int limit = 20});
  Stream<List<AppUser>> donorsOfMonth(String monthKey);
}

abstract class ItemRepository {
  Stream<List<Item>> latestItems();
  Stream<List<Item>> itemsByDonor(String donorId);
  Stream<Item?> watchItem(String id);
  String newItemId();
  Future<void> createItem(Item item);
  Future<void> setStatus(String itemId, String status);
}

abstract class NeedRepository {
  Stream<List<Need>> latestNeeds();
  Stream<List<Need>> needsBy(String requesterId);
  Stream<Need?> watchNeed(String id);
  Future<String> createNeed(Need need);
  Future<void> setStatus(String needId, String status);

  /// Tells the requester that [itemId] (posted by the current user) matches.
  Future<void> notifyMatch({
    required Need need,
    required String itemId,
    required String itemTitle,
    required String donorUid,
  });
}

abstract class RequestRepository {
  Stream<List<ShareRequest>> requestsWhere(String field, String uid);
  Stream<List<ShareRequest>> requestsForItem(String itemId, String donorUid);
  Stream<ShareRequest?> watchRequest(String id);
  Future<ShareRequest?> getRequest(String id);

  Future<void> create({
    required String requestId,
    required Item item,
    required String requesterUid,
    required String reason,
  });
  Future<void> accept(ShareRequest request, List<ShareRequest> othersToDecline);
  Future<void> reject(ShareRequest request);
  Future<void> complete(ShareRequest request, Map<String, dynamic> donorCounters);
  Future<void> cancel(ShareRequest request);
  Future<void> setHandoverMethod(String requestId, String methodId);
}

abstract class ReviewRepository {
  Future<bool> exists(String reviewId);
  Future<void> create(String reviewId, Map<String, dynamic> data);
  Stream<List<Review>> reviewsFor(String userId);
}

abstract class ReportRepository {
  /// Returns false if this report already exists (one per user per target).
  Future<bool> create(String reportId, Map<String, dynamic> data);
  Stream<List<Report>> allReports();
  Future<void> setStatus(String reportId, String status);
}

abstract class NotificationRepository {
  Stream<List<AppNotification>> notificationsFor(String uid);
  Future<void> markRead(String id);
  Future<void> markAllRead(List<String> ids);
}

abstract class ImageStorage {
  bool get isConfigured;
  Future<XFile?> pickOne();
  Future<List<XFile>> pickMany(int max);
  Future<String> upload(XFile file, {required String folder});
}

abstract class LocationProvider {
  /// Current GPS position, or throws a friendly error message (String).
  Future<GeoPoint2> currentPosition();
}
