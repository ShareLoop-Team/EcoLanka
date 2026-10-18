// In-app notifications (free plan — no Cloud Functions / FCM push).
//
// notifications/{id} docs are written by request_service.dart in the same
// batch as each request change. This service streams the signed-in user's
// notifications for a notifications screen / badge, and reports new ones
// as they arrive so the UI can show a banner or SnackBar.
//
// System (lock-screen) notifications can be added later with
// flutter_local_notifications on mobile — call it from [onNew].

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? requestId;
  final String? itemId;
  final bool read;
  final DateTime? createdAt;

  AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc)
      : id = doc.id,
        type = doc.data()?['type'] as String? ?? 'system',
        title = doc.data()?['title'] as String? ?? 'Shareloop',
        body = doc.data()?['body'] as String? ?? '',
        requestId = doc.data()?['requestId'] as String?,
        itemId = doc.data()?['itemId'] as String?,
        read = doc.data()?['read'] as bool? ?? false,
        createdAt = (doc.data()?['createdAt'] as Timestamp?)?.toDate();
}

class NotificationService {
  NotificationService._();

  static final _db = FirebaseFirestore.instance;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  /// Latest 30 notifications for the signed-in user (needs the
  /// notifications userId+createdAt index from backend/firestore.indexes.json).
  static Stream<List<AppNotification>> myNotifications() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map(AppNotification.fromDoc).toList());
  }

  /// Unread count, for a badge on the bell icon.
  static Stream<int> unreadCount() =>
      myNotifications().map((list) => list.where((n) => !n.read).length);

  /// Calls [onNew] for each unread notification that arrives after start().
  /// Call after login; call stop() on logout.
  static Future<void> start(void Function(AppNotification n) onNew) async {
    await stop();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    var first = true;
    _sub = _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .listen((snap) {
      if (first) {
        first = false; // existing history — don't pop up
        return;
      }
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final n = AppNotification.fromDoc(change.doc);
        if (!n.read) onNew(n);
      }
    });
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  static Future<void> markRead(String id) =>
      _db.collection('notifications').doc(id).update({'read': true});
}
