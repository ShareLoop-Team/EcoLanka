// ItemController — give-away posts: browse, filter, share, manage (MVC).

import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../models/item.dart';
import '../models/need.dart';
import '../repositories/repositories.dart';
import '../utils/anti_resell_policy.dart';
import '../utils/district_locator.dart';

class ItemFilter {
  final String query;
  final String? categoryId;
  final String? condition;
  final String? district;

  const ItemFilter({
    this.query = '',
    this.categoryId,
    this.condition,
    this.district,
  });
}

class ItemController {
  ItemController({
    required ItemRepository items,
    required NeedRepository needs,
    required ImageStorage images,
    required AuthRepository auth,
  })  : _items = items,
        _needs = needs,
        _images = images,
        _auth = auth;

  final ItemRepository _items;
  final NeedRepository _needs;
  final ImageStorage _images;
  final AuthRepository _auth;

  String? get currentUid => _auth.currentUid;

  // ---------- reads ----------

  /// Newest available items.
  Stream<List<Item>> availableItems() => _items.latestItems().map(
      (list) => list.where((i) => i.status == 'available').toList());

  /// Everything the signed-in user has posted, newest first.
  Stream<List<Item>> myItems() {
    final uid = _auth.currentUid;
    if (uid == null) return Stream.value(const []);
    return _items.itemsByDonor(uid).map((list) => list..sort(newestFirst));
  }

  Stream<Item?> watchItem(String id) => _items.watchItem(id);

  // ---------- filtering (pure, unit-tested) ----------

  /// Search + category / condition / district filter. Hides my own posts.
  List<Item> filter(List<Item> items, ItemFilter f) {
    final q = f.query.trim().toLowerCase();
    final me = _auth.currentUid;
    return items.where((i) {
      if (i.donorId == me) return false;
      if (f.categoryId != null && i.categoryId != f.categoryId) return false;
      if (f.condition != null && i.condition != f.condition) return false;
      if (f.district != null && i.district != f.district) return false;
      if (q.isEmpty) return true;
      return i.title.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q) ||
          i.city.toLowerCase().contains(q) ||
          i.district.toLowerCase().contains(q);
    }).toList();
  }

  /// Closest districts first (location & district filtering, docs §2.3).
  static List<Item> sortByProximity(List<Item> items, String myDistrict) {
    final sorted = [...items];
    sorted.sort((a, b) => DistrictLocator.districtDistanceKm(myDistrict, a.district)
        .compareTo(DistrictLocator.districtDistanceKm(myDistrict, b.district)));
    return sorted;
  }

  static int newestFirst(Item a, Item b) =>
      (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());

  // ---------- share an item ----------

  bool get photoUploadsEnabled => _images.isConfigured;

  Future<List<XFile>> pickImages() => _images.pickMany(AppConfig.maxItemImages);

  /// Validates, uploads photos and publishes the item.
  /// If [forNeed] is given, the person who posted that need is notified.
  Future<String> createItem({
    required String title,
    required String description,
    required String categoryId,
    required String condition,
    required String district,
    required String city,
    List<XFile> photos = const [],
    Need? forNeed,
  }) async {
    final uid = _auth.currentUid;
    if (uid == null) throw StateError('Not signed in.');
    if (AntiResellPolicy.looksLikeSale('$title $description')) {
      throw StateError(AntiResellPolicy.blockedMessage);
    }

    final id = _items.newItemId();
    final urls = <String>[];
    if (photos.isNotEmpty && _images.isConfigured) {
      for (final p in photos.take(AppConfig.maxItemImages)) {
        urls.add(await _images.upload(p, folder: 'items/$id'));
      }
    }
    final item = Item(
      id: id,
      donorId: uid,
      title: title.trim(),
      description: description.trim(),
      categoryId: categoryId,
      condition: condition,
      images: urls,
      district: district,
      city: city.trim(),
    );
    await _items.createItem(item);

    if (forNeed != null && forNeed.requesterId != uid) {
      await _needs.notifyMatch(
        need: forNeed,
        itemId: id,
        itemTitle: item.title,
        donorUid: uid,
      );
    }
    return id;
  }

  /// Donor (or admin) changes status: available / reserved / donated / removed.
  Future<void> setStatus(String itemId, String status) =>
      _items.setStatus(itemId, status);
}
