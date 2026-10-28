// API implementation of ReviewRepository — /reviews.

import '../models/rating.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

class ApiReviewService implements ReviewRepository {
  ApiReviewService(this._api);

  final ApiClient _api;

  /// [reviewId] is "{requestId}_{myUid}"; the server checks it for the signed-in user.
  @override
  Future<bool> exists(String reviewId) async {
    final uid = _api.uid;
    final requestId = uid != null && reviewId.endsWith('_$uid')
        ? reviewId.substring(0, reviewId.length - uid.length - 1)
        : reviewId;
    final json = await _api.get('/reviews/mine', query: {'requestId': requestId})
        as Map<String, dynamic>;
    return json['exists'] == true;
  }

  @override
  Future<void> create(String reviewId, Map<String, dynamic> data) => _api.post('/reviews', {
        'requestId': data['requestId'],
        'rating': data['rating'],
        'comment': data['comment'] ?? '',
      });

  @override
  Stream<List<Review>> reviewsFor(String userId) => _api.watch(
        '/reviews',
        (json) => jsonList(json).map(Review.fromJson).toList(),
        query: {'revieweeId': userId},
        every: const Duration(seconds: 30),
      );
}
