// NeedController — "Item Requests" module: post what you need + why (MVC).

import '../models/need.dart';
import '../repositories/repositories.dart';
import '../utils/anti_resell_policy.dart';
import '../utils/validators.dart';

class NeedController {
  NeedController({required NeedRepository needs, required AuthRepository auth})
      : _needs = needs,
        _auth = auth;

  final NeedRepository _needs;
  final AuthRepository _auth;

  String? get currentUid => _auth.currentUid;

  /// Open needs from other people, newest first.
  Stream<List<Need>> openNeeds() => _needs.latestNeeds().map((list) =>
      list.where((n) => n.isOpen && n.requesterId != _auth.currentUid).toList());

  Stream<List<Need>> myNeeds() {
    final uid = _auth.currentUid;
    if (uid == null) return Stream.value(const []);
    return _needs.needsBy(uid).map((list) => list
      ..sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now())));
  }

  Stream<Need?> watchNeed(String id) => _needs.watchNeed(id);

  List<Need> filter(List<Need> needs, {String query = '', String? categoryId, String? district}) {
    final q = query.trim().toLowerCase();
    return needs.where((n) {
      if (categoryId != null && n.categoryId != categoryId) return false;
      if (district != null && n.district != district) return false;
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) ||
          n.description.toLowerCase().contains(q) ||
          n.reason.toLowerCase().contains(q);
    }).toList();
  }

  /// Posts a need. The anti-resell declaration must be accepted.
  Future<String> createNeed({
    required String title,
    required String description,
    required String reason,
    required String categoryId,
    required String district,
    required String city,
    required bool agreedNoResell,
  }) async {
    final uid = _auth.currentUid;
    if (uid == null) throw StateError('Not signed in.');
    if (!agreedNoResell) {
      throw StateError('Please accept: "${AntiResellPolicy.declaration}"');
    }
    final titleError = Validators.needTitle(title);
    if (titleError != null) throw StateError(titleError);
    final reasonError = Validators.requestMessage(reason);
    if (reasonError != null) throw StateError(reasonError);

    return _needs.createNeed(Need(
      id: '',
      requesterId: uid,
      title: title.trim(),
      description: description.trim(),
      reason: reason.trim(),
      categoryId: categoryId,
      district: district,
      city: city.trim(),
    ));
  }

  Future<void> markFulfilled(String needId) => _needs.setStatus(needId, 'fulfilled');
  Future<void> close(String needId) => _needs.setStatus(needId, 'closed');
}
