// API implementation of UserRepository — /users.

import '../models/user.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

class ApiUserService implements UserRepository {
  ApiUserService(this._api);

  final ApiClient _api;

  static AppUser _user(Map<String, dynamic> m) => AppUser.fromMap(m['uid'] as String, m);

  static List<AppUser> _users(dynamic json) => jsonList(json).map(_user).toList();

  @override
  Future<AppUser?> getUser(String uid) async {
    final json = await _api.getOrNull('/users/$uid');
    return json == null ? null : _user(json as Map<String, dynamic>);
  }

  @override
  Stream<AppUser?> watchUser(String uid) => _api.watch(
      '/users/$uid', (json) => json == null ? null : _user(json as Map<String, dynamic>));

  /// First-time profile. The server sets the uid, counters and timestamps.
  @override
  Future<void> createUser(String uid, Map<String, dynamic> data) => _api.post('/users', {
        'displayName': data['displayName'],
        'district': data['district'],
        'role': data['role'],
        'language': data['language'],
        if (data['email'] != null) 'email': data['email'],
      });

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> fields) =>
      _api.patch('/users/$uid', fields);

  @override
  Stream<List<AppUser>> topDonors({int limit = 20}) =>
      _api.watch('/users/leaderboard', _users, query: {'limit': '$limit'}, every: const Duration(seconds: 30));

  @override
  Stream<List<AppUser>> donorsOfMonth(String monthKey) =>
      _api.watch('/users/monthly', _users, query: {'month': monthKey}, every: const Duration(seconds: 30));
}
