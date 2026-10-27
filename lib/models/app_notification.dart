// GET /notifications — written by the server alongside each change.

import '../utils/json.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? requestId;
  final String? itemId;
  final String? needId;
  final bool read;
  final DateTime? createdAt;

  AppNotification.fromJson(Map<String, dynamic> m)
      : id = m['id'] as String? ?? '',
        type = m['type'] as String? ?? 'system',
        title = m['title'] as String? ?? 'Shareloop',
        body = m['body'] as String? ?? '',
        requestId = m['requestId'] as String?,
        itemId = m['itemId'] as String?,
        needId = m['needId'] as String?,
        read = m['read'] as bool? ?? false,
        createdAt = parseDate(m['createdAt']);
}
