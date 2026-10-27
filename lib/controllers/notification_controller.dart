// NotificationController — in-app notifications, bell badge, live banners.

import 'dart:async';

import '../models/app_notification.dart';
import '../repositories/repositories.dart';

class NotificationController {
  NotificationController({
    required NotificationRepository notifications,
    required AuthRepository auth,
  })  : _repo = notifications,
        _auth = auth;

  final NotificationRepository _repo;
  final AuthRepository _auth;
  StreamSubscription<List<AppNotification>>? _sub;

  /// The signed-in user's notifications, newest first.
  Stream<List<AppNotification>> myNotifications() {
    final uid = _auth.currentUid;
    if (uid == null) return Stream.value(const []);
    return _repo.notificationsFor(uid).map((list) => list
      ..sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now())));
  }

  Stream<int> unreadCount() =>
      myNotifications().map((list) => list.where((n) => !n.read).length);

  /// Calls [onNew] for each unread notification that arrives after start().
  Future<void> start(void Function(AppNotification n) onNew) async {
    await stop();
    final seen = <String>{};
    var first = true;
    _sub = myNotifications().listen((list) {
      if (first) {
        seen.addAll(list.map((n) => n.id)); // existing history — no pop-ups
        first = false;
        return;
      }
      for (final n in list) {
        if (seen.add(n.id) && !n.read) onNew(n);
      }
    }, onError: (_) {});
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> markRead(String id) => _repo.markRead(id);

  Future<void> markAllRead(List<AppNotification> list) =>
      _repo.markAllRead(list.where((n) => !n.read).map((n) => n.id).toList());
}
