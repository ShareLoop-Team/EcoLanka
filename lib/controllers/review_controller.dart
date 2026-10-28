// ReviewController — two-way star ratings after a completed exchange.

import '../models/rating.dart';
import '../models/request.dart';
import '../repositories/repositories.dart';
import '../utils/validators.dart';

class ReviewController {
  ReviewController({required ReviewRepository reviews, required AuthRepository auth})
      : _reviews = reviews,
        _auth = auth;

  final ReviewRepository _reviews;
  final AuthRepository _auth;

  static String reviewIdFor(String requestId, String reviewerId) =>
      '${requestId}_$reviewerId';

  Future<bool> hasReviewed(String requestId) {
    final uid = _auth.currentUid;
    if (uid == null) return Future.value(false);
    return _reviews.exists(reviewIdFor(requestId, uid));
  }

  Future<void> leaveReview({
    required ShareRequest request,
    required int rating,
    required String comment,
  }) {
    final uid = _auth.currentUid;
    if (uid == null) throw StateError('Not signed in.');
    if (!request.isCompleted) throw StateError('You can review after the handover.');
    if (rating < 1 || rating > 5) throw StateError('Pick 1 to 5 stars.');
    final error = Validators.reviewComment(comment);
    if (error != null) throw StateError(error);

    final revieweeId = uid == request.donorId ? request.requesterId : request.donorId;
    return _reviews.create(reviewIdFor(request.id, uid), {
      'requestId': request.id,
      'reviewerId': uid,
      'revieweeId': revieweeId,
      'rating': rating,
      'comment': comment.trim(),
    });
  }

  Stream<List<Review>> reviewsFor(String userId) => _reviews.reviewsFor(userId).map(
      (list) => list
        ..sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now())));

  Stream<RatingSummary> ratingFor(String userId) =>
      _reviews.reviewsFor(userId).map(RatingSummary.fromReviews);
}
