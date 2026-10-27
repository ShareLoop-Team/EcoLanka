// API implementation of RequestRepository — /requests.
//
// Each action is ONE call; the server runs it in a database transaction that
// also updates the item, the counters and writes the notification(s).

import '../models/item.dart';
import '../models/request.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

class ApiRequestService implements RequestRepository {
  ApiRequestService(this._api);

  final ApiClient _api;

  static List<ShareRequest> _list(dynamic json) =>
      jsonList(json).map(ShareRequest.fromJson).toList();

  static ShareRequest? _one(dynamic json) =>
      json == null ? null : ShareRequest.fromJson(json as Map<String, dynamic>);

  // ---------- reads ----------

  /// [field] is `requesterId` (sent) or `donorId` (received).
  @override
  Stream<List<ShareRequest>> requestsWhere(String field, String uid) =>
      _api.watch('/requests', _list, query: {'as': field == 'donorId' ? 'donor' : 'requester'});

  @override
  Stream<List<ShareRequest>> requestsForItem(String itemId, String donorUid) =>
      _api.watch('/requests', _list, query: {'itemId': itemId});

  @override
  Stream<ShareRequest?> watchRequest(String id) =>
      _api.watch('/requests/${Uri.encodeComponent(id)}', _one);

  @override
  Future<ShareRequest?> getRequest(String id) async =>
      _one(await _api.getOrNull('/requests/${Uri.encodeComponent(id)}'));

  // ---------- writes ----------

  @override
  Future<void> create({
    required String requestId,
    required Item item,
    required String requesterUid,
    required String reason,
  }) =>
      _api.post('/requests', {
        'requestId': requestId,
        'itemId': item.id,
        'message': reason,
        'antiResellAgreed': true,
      });

  /// The server also declines every other pending request for the item.
  @override
  Future<void> accept(ShareRequest request, List<ShareRequest> othersToDecline) =>
      _api.post('/requests/${Uri.encodeComponent(request.id)}/accept');

  @override
  Future<void> reject(ShareRequest request) =>
      _api.post('/requests/${Uri.encodeComponent(request.id)}/reject');

  /// The server updates the donor's counters itself ([donorCounters] is ignored).
  @override
  Future<void> complete(ShareRequest request, Map<String, dynamic> donorCounters) =>
      _api.post('/requests/${Uri.encodeComponent(request.id)}/complete');

  @override
  Future<void> cancel(ShareRequest request) =>
      _api.post('/requests/${Uri.encodeComponent(request.id)}/cancel');

  @override
  Future<void> setHandoverMethod(String requestId, String methodId) =>
      _api.patch('/requests/${Uri.encodeComponent(requestId)}/handover', {'handoverMethod': methodId});
}
