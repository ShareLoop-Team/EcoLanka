// reviews/{requestId}_{reviewerId} — see docs/SCHEMA.md

import '../utils/json.dart';

class Review {
  final String id;
  final String requestId;
  final String reviewerId;
  final String revieweeId;
  final int rating; // 1–5
  final String comment;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.requestId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> m) {
    return Review(
      id: m['id'] as String? ?? '',
      requestId: m['requestId'] as String? ?? '',
      reviewerId: m['reviewerId'] as String? ?? '',
      revieweeId: m['revieweeId'] as String? ?? '',
      rating: (m['rating'] as num?)?.toInt() ?? 0,
      comment: m['comment'] as String? ?? '',
      createdAt: parseDate(m['createdAt']),
    );
  }
}

class RatingSummary {
  final double average;
  final int count;

  const RatingSummary(this.average, this.count);

  static const empty = RatingSummary(0, 0);

  factory RatingSummary.fromReviews(List<Review> reviews) {
    if (reviews.isEmpty) return empty;
    final total = reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return RatingSummary(total / reviews.length, reviews.length);
  }
}
