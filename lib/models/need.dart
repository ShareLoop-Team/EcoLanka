// needs/{needId} — "Item Requests" posts: someone describes what they need
// and why. Donors can answer by sharing a matching item.

import '../utils/json.dart';

class Need {
  final String id;
  final String requesterId;
  final String title;
  final String description;
  final String reason;
  final String categoryId;
  final String district;
  final String city;
  final String status; // open | fulfilled | closed
  final DateTime? createdAt;

  const Need({
    required this.id,
    required this.requesterId,
    required this.title,
    required this.description,
    required this.reason,
    required this.categoryId,
    required this.district,
    required this.city,
    this.status = 'open',
    this.createdAt,
  });

  bool get isOpen => status == 'open';

  factory Need.fromJson(Map<String, dynamic> m) {
    return Need(
      id: m['id'] as String? ?? '',
      requesterId: m['requesterId'] as String? ?? '',
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      reason: m['reason'] as String? ?? '',
      categoryId: m['categoryId'] as String? ?? 'other',
      district: m['district'] as String? ?? '',
      city: m['city'] as String? ?? '',
      status: m['status'] as String? ?? 'open',
      createdAt: parseDate(m['createdAt']),
    );
  }

  /// Body for POST /needs (the server sets requester, status and timestamps).
  Map<String, dynamic> toNewJson() => {
        'title': title,
        'description': description,
        'reason': reason,
        'categoryId': categoryId,
        'district': district,
        'city': city,
        'antiResellAgreed': true,
      };
}
