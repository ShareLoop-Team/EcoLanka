// requests/{requestId} — see docs/SCHEMA.md
// Create/accept/reject/complete/cancel: lib/services/request_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ShareRequest {
  final String id;
  final String itemId;
  final String itemTitle;
  final String donorId;
  final String requesterId;
  final String message;
  final String status; // pending | accepted | rejected | cancelled | completed
  final DateTime? createdAt;

  const ShareRequest({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.donorId,
    required this.requesterId,
    required this.message,
    required this.status,
    this.createdAt,
  });

  bool get isPending => status == 'pending';

  factory ShareRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return ShareRequest(
      id: doc.id,
      itemId: m['itemId'] as String,
      itemTitle: m['itemTitle'] as String? ?? '',
      donorId: m['donorId'] as String,
      requesterId: m['requesterId'] as String,
      message: m['message'] as String? ?? '',
      status: m['status'] as String? ?? 'pending',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
