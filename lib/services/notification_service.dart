// API implementation of NotificationRepository — /notifications.
// Notifications are written by the server alongside each request change.

import '../models/app_notification.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

class ApiNotificationService implements NotificationRepository {
  ApiNotificationService(this._api);

  final ApiClient _api;

  @override
  Stream<List<AppNotification>> notificationsFor(String uid) => _api.watch(
      '/notifications', (json) => jsonList(json).map(AppNotification.fromJson).toList());

  @override
  Future<void> markRead(String id) => _api.post('/notifications/$id/read');

  @override
  Future<void> markAllRead(List<String> ids) async {
    if (ids.isEmpty) return;
    await _api.post('/notifications/read', {'ids': ids});
  }
}
