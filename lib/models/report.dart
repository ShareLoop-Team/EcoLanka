// reports/{targetType}_{targetId}_{reporterUid} — see docs/SCHEMA.md

import '../utils/json.dart';

class Report {
  final String id;
  final String reporterId;
  final String targetType; // user | item
  final String targetId;
  final String reason;
  final String details;
  final String status; // open | reviewing | resolved | dismissed
  final DateTime? createdAt;

  Report.fromJson(Map<String, dynamic> m)
      : id = m['id'] as String? ?? '',
        reporterId = m['reporterId'] as String? ?? '',
        targetType = m['targetType'] as String? ?? 'item',
        targetId = m['targetId'] as String? ?? '',
        reason = m['reason'] as String? ?? 'other',
        details = m['details'] as String? ?? '',
        status = m['status'] as String? ?? 'open',
        createdAt = parseDate(m['createdAt']);
}
