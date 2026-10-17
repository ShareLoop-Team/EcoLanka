// items/{itemId} — see docs/SCHEMA.md

import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String donorId;
  final String title;
  final String description;
  final String categoryId;
  final String condition; // new | like_new | good | fair
  final List<String> images; // Cloudinary URLs, max 5
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

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return Item(
      id: doc.id,
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
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Fields for a new item (status/counters/timestamps set here).
  Map<String, dynamic> toNewDoc() => {
        'donorId': donorId,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'condition': condition,
        'images': images,
        'district': district,
        'city': city,
        'status': 'available',
        'requestCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
