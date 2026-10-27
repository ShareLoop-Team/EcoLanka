// API implementation of NeedRepository — /needs.

import '../models/need.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

class ApiNeedService implements NeedRepository {
  ApiNeedService(this._api);

  final ApiClient _api;

  static List<Need> _needs(dynamic json) => jsonList(json).map(Need.fromJson).toList();

  @override
  Stream<List<Need>> latestNeeds() => _api.watch('/needs', _needs);

  @override
  Stream<List<Need>> needsBy(String requesterId) =>
      _api.watch('/needs', _needs, query: {'requesterId': requesterId});

  @override
  Stream<Need?> watchNeed(String id) => _api.watch(
      '/needs/$id', (json) => json == null ? null : Need.fromJson(json as Map<String, dynamic>));

  @override
  Future<String> createNeed(Need need) async {
    final json = await _api.post('/needs', need.toNewJson()) as Map<String, dynamic>;
    return json['id'] as String;
  }

  @override
  Future<void> setStatus(String needId, String status) =>
      _api.patch('/needs/$needId/status', {'status': status});

  /// The server checks the item is mine and writes the notification.
  @override
  Future<void> notifyMatch({
    required Need need,
    required String itemId,
    required String itemTitle,
    required String donorUid,
  }) =>
      _api.post('/needs/${need.id}/match', {'itemId': itemId});
}
