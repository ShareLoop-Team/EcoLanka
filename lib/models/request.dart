// requests/{itemId}_{requesterUid} — see docs/SCHEMA.md
// Business logic: lib/controllers/request_controller.dart

import '../utils/json.dart';
import 'handover_method.dart';

class ShareRequest {
  final String id;
  final String itemId;
  final String itemTitle;
  final String donorId;
  final String requesterId;

  /// The requester's reason for needing the item (shown to the donor).
  final String message;
  final String status; // pending | accepted | rejected | cancelled | completed
  final bool antiResellAgreed;
  final String? handoverMethod; // direct | courier | on_demand
  final DateTime? createdAt;

  const ShareRequest({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.donorId,
    required this.requesterId,
    required this.message,
    required this.status,
    this.antiResellAgreed = false,
    this.handoverMethod,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';

  HandoverMethod? get handover => HandoverMethods.byId(handoverMethod);

  factory ShareRequest.fromJson(Map<String, dynamic> m) {
    return ShareRequest(
      id: m['id'] as String,
      itemId: m['itemId'] as String,
      itemTitle: m['itemTitle'] as String? ?? '',
      donorId: m['donorId'] as String,
      requesterId: m['requesterId'] as String,
      message: m['message'] as String? ?? '',
      status: m['status'] as String? ?? 'pending',
      antiResellAgreed: m['antiResellAgreed'] as bool? ?? false,
      handoverMethod: m['handoverMethod'] as String?,
      createdAt: parseDate(m['createdAt']),
    );
  }
}
