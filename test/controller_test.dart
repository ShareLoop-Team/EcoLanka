// QA (Umayanga): controllers tested with FAKE repositories — no Firebase.
// This works because controllers depend on abstractions (Dependency Inversion).
import 'package:ecolanka/controllers/item_controller.dart';
import 'package:ecolanka/controllers/need_controller.dart';
import 'package:ecolanka/controllers/request_controller.dart';
import 'package:ecolanka/models/item.dart';
import 'package:ecolanka/models/need.dart';
import 'package:ecolanka/models/user.dart';
import 'package:ecolanka/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------- fakes (only the members a test uses are implemented) ----------

class FakeAuth implements AuthRepository {
  FakeAuth(this.uid);
  final String? uid;

  @override
  String? get currentUid => uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeItems implements ItemRepository {
  final List<Item> created = [];
  int _next = 0;

  @override
  String newItemId() => 'item${_next++}';

  @override
  Future<void> createItem(Item item) async => created.add(item);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNeeds implements NeedRepository {
  final List<String> notified = [];
  final List<Need> created = [];

  @override
  Future<String> createNeed(Need need) async {
    created.add(need);
    return 'need1';
  }

  @override
  Future<void> notifyMatch({
    required Need need,
    required String itemId,
    required String itemTitle,
    required String donorUid,
  }) async =>
      notified.add('${need.id}:$itemId');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeImages implements ImageStorage {
  @override
  bool get isConfigured => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRequests implements RequestRepository {
  final List<String> createdIds = [];

  @override
  Future<void> create({
    required String requestId,
    required Item item,
    required String requesterUid,
    required String reason,
  }) async =>
      createdIds.add(requestId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUsers implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Item _item({String donorId = 'donor1', String status = 'available', String district = 'Colombo'}) => Item(
      id: 'i1',
      donorId: donorId,
      title: 'Science textbook',
      description: 'Grade 10',
      categoryId: 'books',
      condition: 'good',
      images: const [],
      district: district,
      city: '',
      status: status,
    );

void main() {
  group('ItemController', () {
    late FakeItems items;
    late FakeNeeds needs;
    late ItemController controller;

    setUp(() {
      items = FakeItems();
      needs = FakeNeeds();
      controller = ItemController(
        items: items,
        needs: needs,
        images: FakeImages(),
        auth: FakeAuth('donor1'),
      );
    });

    test('creates an item for the signed-in donor', () async {
      final id = await controller.createItem(
        title: 'Kids shoes',
        description: 'Size 3, good condition',
        categoryId: 'shoes',
        condition: 'good',
        district: 'Galle',
        city: 'Galle',
      );
      expect(id, 'item0');
      expect(items.created.single.donorId, 'donor1');
      expect(items.created.single.status, 'available');
    });

    test('blocks sale wording before touching the repository', () async {
      await expectLater(
        controller.createItem(
          title: 'Chair for sale',
          description: 'Rs. 2000',
          categoryId: 'household',
          condition: 'used',
          district: 'Galle',
          city: '',
        ),
        throwsStateError,
      );
      expect(items.created, isEmpty);
    });

    test('answering a need notifies its poster', () async {
      const need = Need(
        id: 'n1', requesterId: 'req1', title: 'Shoes', description: '',
        reason: 'For school', categoryId: 'shoes', district: 'Galle', city: '',
      );
      await controller.createItem(
        title: 'Kids shoes', description: 'Size 3', categoryId: 'shoes',
        condition: 'good', district: 'Galle', city: '', forNeed: need,
      );
      expect(needs.notified, ['n1:item0']);
    });

    test('filter hides my own items and applies category/search', () {
      final list = [
        _item(donorId: 'donor1'),
        _item(donorId: 'other'),
        Item(
          id: 'i2', donorId: 'other', title: 'Rice cooker', description: '',
          categoryId: 'household', condition: 'used', images: const [],
          district: 'Kandy', city: '',
        ),
      ];
      expect(controller.filter(list, const ItemFilter()).length, 2);
      expect(controller.filter(list, const ItemFilter(categoryId: 'household')).single.id, 'i2');
      expect(controller.filter(list, const ItemFilter(query: 'science')).length, 1);
      expect(controller.filter(list, const ItemFilter(district: 'Kandy')).length, 1);
    });

    test('sortByProximity puts nearer districts first', () {
      final sorted = ItemController.sortByProximity(
        [_item(district: 'Jaffna'), _item(district: 'Gampaha'), _item(district: 'Colombo')],
        'Colombo',
      );
      expect(sorted.map((i) => i.district), ['Colombo', 'Gampaha', 'Jaffna']);
    });
  });

  group('RequestController', () {
    late FakeRequests requests;
    late RequestController controller;

    setUp(() {
      requests = FakeRequests();
      controller = RequestController(
        requests: requests,
        users: FakeUsers(),
        auth: FakeAuth('req1'),
      );
    });

    test('requires the anti-resell declaration', () async {
      await expectLater(
        controller.createRequest(item: _item(), reason: 'For my brother', agreedNoResell: false),
        throwsStateError,
      );
      expect(requests.createdIds, isEmpty);
    });

    test('requires a reason of at least 5 characters', () async {
      await expectLater(
        controller.createRequest(item: _item(), reason: 'pls', agreedNoResell: true),
        throwsStateError,
      );
    });

    test('cannot request own or unavailable items', () async {
      final own = RequestController(
          requests: requests, users: FakeUsers(), auth: FakeAuth('donor1'));
      await expectLater(
        own.createRequest(item: _item(), reason: 'I want it back', agreedNoResell: true),
        throwsStateError,
      );
      await expectLater(
        controller.createRequest(
            item: _item(status: 'reserved'), reason: 'For school', agreedNoResell: true),
        throwsStateError,
      );
    });

    test('valid request uses id itemId_uid (one request per item)', () async {
      final id = await controller.createRequest(
          item: _item(), reason: 'For my school work', agreedNoResell: true);
      expect(id, 'i1_req1');
      expect(requests.createdIds, ['i1_req1']);
    });

    test('monthly counters: +1 in the same month, reset in a new month', () {
      final now = DateTime.utc(2026, 10, 18);
      const sameMonth = AppUser(
          uid: 'd', displayName: 'D', role: 'both', language: 'en', district: 'Galle',
          donationCount: 7, monthKey: '2026-10', monthDonations: 2);
      const oldMonth = AppUser(
          uid: 'd', displayName: 'D', role: 'both', language: 'en', district: 'Galle',
          donationCount: 7, monthKey: '2026-9', monthDonations: 5);
      expect(RequestController.donorCountersAfterDonation(sameMonth, now),
          {'donationCount': 8, 'monthKey': '2026-10', 'monthDonations': 3});
      expect(RequestController.donorCountersAfterDonation(oldMonth, now),
          {'donationCount': 8, 'monthKey': '2026-10', 'monthDonations': 1});
    });
  });

  group('NeedController', () {
    test('needs the declaration and a reason', () async {
      final needs = FakeNeeds();
      final c = NeedController(needs: needs, auth: FakeAuth('req1'));
      await expectLater(
        c.createNeed(
          title: 'A/L notes', description: '', reason: 'Exam next month',
          categoryId: 'books', district: 'Kandy', city: '', agreedNoResell: false,
        ),
        throwsStateError,
      );
      final id = await c.createNeed(
        title: 'A/L notes', description: '', reason: 'Exam next month',
        categoryId: 'books', district: 'Kandy', city: '', agreedNoResell: true,
      );
      expect(id, 'need1');
      expect(needs.created.single.requesterId, 'req1');
    });
  });
}
