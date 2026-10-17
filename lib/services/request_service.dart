// Shareloop – request flow (free plan, replaces Cloud Functions)
//
// Every action is ONE batched write: the request change, the item/counter
// change and the notification for the other person succeed or fail together.
// backend/firestore.rules checks each part, so the app can't write anything it shouldn't.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Map<String, dynamic> _notification({
    required String to,
    required String type,
    required String title,
    required String body,
    required String requestId,
    required String itemId,
  }) =>
      {
        'userId': to,
        'senderId': _uid,
        'type': type,
        'title': title,
        'body': body,
        'requestId': requestId,
        'itemId': itemId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Requester asks for an item.
  static Future<String> createRequest({
    required String itemId,
    required String itemTitle,
    required String donorId,
    required String message,
  }) async {
    final reqRef = _db.collection('requests').doc();
    final batch = _db.batch()
      ..set(reqRef, {
        'itemId': itemId,
        'itemTitle': itemTitle,
        'donorId': donorId,
        'requesterId': _uid,
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(_db.collection('items').doc(itemId), {'requestCount': FieldValue.increment(1)})
      ..update(_db.collection('users').doc(_uid), {'requestCount': FieldValue.increment(1)})
      ..set(
        _db.collection('notifications').doc(),
        _notification(
          to: donorId,
          type: 'new_request',
          title: 'New request for your item',
          body: 'Someone requested "$itemTitle"',
          requestId: reqRef.id,
          itemId: itemId,
        ),
      );
    await batch.commit();
    return reqRef.id;
  }

  /// Donor accepts → item becomes reserved, requester is notified.
  static Future<void> accept(DocumentSnapshot<Map<String, dynamic>> req) async {
    final d = req.data()!;
    await (_db.batch()
          ..update(req.reference, {'status': 'accepted', 'updatedAt': FieldValue.serverTimestamp()})
          ..update(_db.collection('items').doc(d['itemId']),
              {'status': 'reserved', 'updatedAt': FieldValue.serverTimestamp()})
          ..set(
            _db.collection('notifications').doc(),
            _notification(
              to: d['requesterId'],
              type: 'request_accepted',
              title: 'Request accepted 🎉',
              body: 'Your request for "${d['itemTitle']}" was accepted',
              requestId: req.id,
              itemId: d['itemId'],
            ),
          ))
        .commit();
  }

  /// Donor rejects.
  static Future<void> reject(DocumentSnapshot<Map<String, dynamic>> req) async {
    final d = req.data()!;
    await (_db.batch()
          ..update(req.reference, {'status': 'rejected', 'updatedAt': FieldValue.serverTimestamp()})
          ..set(
            _db.collection('notifications').doc(),
            _notification(
              to: d['requesterId'],
              type: 'request_rejected',
              title: 'Request update',
              body: 'Your request for "${d['itemTitle']}" was not accepted',
              requestId: req.id,
              itemId: d['itemId'],
            ),
          ))
        .commit();
  }

  /// Donor marks the hand-over as done → item donated, donor's count +1.
  static Future<void> complete(DocumentSnapshot<Map<String, dynamic>> req) async {
    final d = req.data()!;
    await (_db.batch()
          ..update(req.reference, {'status': 'completed', 'updatedAt': FieldValue.serverTimestamp()})
          ..update(_db.collection('items').doc(d['itemId']),
              {'status': 'donated', 'updatedAt': FieldValue.serverTimestamp()})
          ..update(_db.collection('users').doc(_uid), {'donationCount': FieldValue.increment(1)})
          ..set(
            _db.collection('notifications').doc(),
            _notification(
              to: d['requesterId'],
              type: 'request_completed',
              title: 'Donation completed',
              body: 'Please leave a review for "${d['itemTitle']}"',
              requestId: req.id,
              itemId: d['itemId'],
            ),
          ))
        .commit();
  }

  /// Requester cancels their own request.
  static Future<void> cancel(DocumentSnapshot<Map<String, dynamic>> req) async {
    final d = req.data()!;
    await (_db.batch()
          ..update(req.reference, {'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()})
          ..set(
            _db.collection('notifications').doc(),
            _notification(
              to: d['donorId'],
              type: 'request_cancelled',
              title: 'Request cancelled',
              body: 'A request for "${d['itemTitle']}" was cancelled',
              requestId: req.id,
              itemId: d['itemId'],
            ),
          ))
        .commit();
  }
}
