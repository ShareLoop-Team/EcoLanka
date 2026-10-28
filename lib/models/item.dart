// GET /items — see docs/SCHEMA.md

import '../utils/json.dart';

class Item {
  final String id;
  final String donorId;
  final String title;
  final String description;
  final String categoryId;
  final String condition; // new | good | used
  final List<String> images; // photo URLs (served by the API), max 5
  final String district;
  final String city;
  final String status; // available | reserved | donated | removed
  final int requestCount;
  final DateTime? createdAt;

  const Item({
    required this.id,
    required this.donorId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.condition,
    required this.images,
    required this.district,
    required this.city,
    this.status = 'available',
    this.requestCount = 0,
    this.createdAt,
  });

  factory Item.fromJson(Map<String, dynamic> m) {
    return Item(
      id: m['id'] as String,
      donorId: m['donorId'] as String,
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      categoryId: m['categoryId'] as String? ?? 'other',
      condition: m['condition'] as String? ?? 'good',
      images: List<String>.from(m['images'] as List? ?? const []),
      district: m['district'] as String? ?? '',
      city: m['city'] as String? ?? '',
      status: m['status'] as String? ?? 'available',
      requestCount: (m['requestCount'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(m['createdAt']),
    );
  }

  /// Body for POST /items (the server sets donor, status, counters, timestamps).
  Map<String, dynamic> toNewJson() => {
        'id': id,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'condition': condition,
        'images': images,
        'district': district,
        'city': city,
      };
}
