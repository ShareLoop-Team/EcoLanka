// API implementation of ItemRepository — /items.

import 'dart:math';

import '../models/item.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

class ApiItemService implements ItemRepository {
  ApiItemService(this._api);

  final ApiClient _api;
  final _random = Random.secure();

  static List<Item> _items(dynamic json) => jsonList(json).map(Item.fromJson).toList();

  @override
  Stream<List<Item>> latestItems() => _api.watch('/items', _items);

  @override
  Stream<List<Item>> itemsByDonor(String donorId) =>
      _api.watch('/items', _items, query: {'donorId': donorId});

  @override
  Stream<Item?> watchItem(String id) => _api.watch(
      '/items/$id', (json) => json == null ? null : Item.fromJson(json as Map<String, dynamic>));

  /// 20-character id made on the device, so photos can be uploaded to
  /// items/{id}/ before the item itself is saved.
  @override
  String newItemId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(20, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  @override
  Future<void> createItem(Item item) => _api.post('/items', item.toNewJson());

  @override
  Future<void> setStatus(String itemId, String status) =>
      _api.patch('/items/$itemId/status', {'status': status});
}
