// RequestController — request an item, donor selection, handover, completion.
// Business rules live here; RequestRepository does the storage (DIP).

import '../models/handover_method.dart';
import '../models/item.dart';
import '../models/request.dart';
import '../models/user.dart';
import '../repositories/repositories.dart';
import '../utils/anti_resell_policy.dart';
import '../utils/validators.dart';

class RequestController {
  RequestController({
    required RequestRepository requests,
    required UserRepository users,
    required AuthRepository auth,
  })  : _requests = requests,
        _users = users,
        _auth = auth;

  final RequestRepository _requests;
  final UserRepository _users;
  final AuthRepository _auth;

  String? get currentUid => _auth.currentUid;

  /// One request per item per user (anti-spam; enforced in the rules too).
  static String requestIdFor(String itemId, String requesterId) =>
      '${itemId}_$requesterId';

  // ---------- reads ----------

  Stream<List<ShareRequest>> sentRequests() {
    final uid = _auth.currentUid;
    if (uid == null) return Stream.value(const []);
    return _requests.requestsWhere('requesterId', uid);
  }

  Stream<List<ShareRequest>> receivedRequests() {
    final uid = _auth.currentUid;
    if (uid == null) return Stream.value(const []);
    return _requests.requestsWhere('donorId', uid);
  }

  /// Donor view: every request for one item, with each requester's reason.
  Stream<List<ShareRequest>> requestsForItem(String itemId) {
    final uid = _auth.currentUid;
    if (uid == null) return Stream.value(const []);
    return _requests.requestsForItem(itemId, uid);
  }

  Stream<ShareRequest?> watchRequest(String id) => _requests.watchRequest(id);

  Future<ShareRequest?> myRequestFor(String itemId) {
    final uid = _auth.currentUid;
    if (uid == null) return Future.value(null);
    return _requests.getRequest(requestIdFor(itemId, uid));
  }

  // ---------- writes ----------

  /// Requester asks for an item with a reason and the anti-resell declaration.
  Future<String> createRequest({
    required Item item,
    required String reason,
    required bool agreedNoResell,
  }) async {
    final uid = _auth.currentUid;
    if (uid == null) throw StateError('Not signed in.');
    if (item.donorId == uid) throw StateError('You cannot request your own item.');
    if (item.status != 'available') throw StateError('This item is no longer available.');
    if (!agreedNoResell) {
      throw StateError('Please accept: "${AntiResellPolicy.declaration}"');
    }
    final error = Validators.requestMessage(reason);
    if (error != null) throw StateError(error);

    final id = requestIdFor(item.id, uid);
    await _requests.create(
      requestId: id,
      item: item,
      requesterUid: uid,
      reason: reason.trim(),
    );
    return id;
  }

  /// Donor selects this requester; all other pending requests are declined.
  Future<void> accept(ShareRequest request) async {
    _requireDonor(request);
    if (!request.isPending) throw StateError('Only pending requests can be accepted.');
    final all = await _requests.requestsForItem(request.itemId, request.donorId).first;
    final others =
        all.where((r) => r.id != request.id && r.isPending).toList();
    await _requests.accept(request, others);
  }

  Future<void> reject(ShareRequest request) {
    _requireDonor(request);
    return _requests.reject(request);
  }

  /// Handover done. Updates the donor's all-time and monthly counters.
  Future<void> complete(ShareRequest request) async {
    _requireDonor(request);
    if (!request.isAccepted) throw StateError('Accept the request first.');
    final donor = await _users.getUser(request.donorId);
    if (donor == null) throw StateError('Donor profile not found.');
    await _requests.complete(request, donorCountersAfterDonation(donor, DateTime.now()));
  }

  Future<void> cancel(ShareRequest request) {
    if (request.requesterId != _auth.currentUid) {
      throw StateError('Only the requester can cancel.');
    }
    return _requests.cancel(request);
  }

  /// Either side picks direct handover, courier or on-demand delivery.
  Future<void> setHandoverMethod(ShareRequest request, HandoverMethod method) {
    final uid = _auth.currentUid;
    if (uid != request.donorId && uid != request.requesterId) {
      throw StateError('Only the donor or requester can choose this.');
    }
    if (!request.isAccepted) {
      throw StateError('Choose a handover method after the request is accepted.');
    }
    return _requests.setHandoverMethod(request.id, method.id);
  }

  void _requireDonor(ShareRequest r) {
    if (r.donorId != _auth.currentUid) {
      throw StateError('Only the donor can do this.');
    }
  }

  /// New counter values after one more donation (monthly leaderboard key is
  /// the UTC month, the same way the API computes it in User::monthKeyNow).
  static Map<String, dynamic> donorCountersAfterDonation(AppUser donor, DateTime now) {
    final key = AppUser.monthKeyFor(now);
    return {
      'donationCount': donor.donationCount + 1,
      'monthKey': key,
      'monthDonations': donor.monthKey == key ? donor.monthDonations + 1 : 1,
    };
  }
}
