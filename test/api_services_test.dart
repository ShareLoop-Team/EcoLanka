// QA: the REST API layer (ApiClient + API services) with a mock HTTP client —
// no server needed.
import 'dart:convert';

import 'package:ecolanka/models/item.dart';
import 'package:ecolanka/services/api_auth_service.dart';
import 'package:ecolanka/services/api_client.dart';
import 'package:ecolanka/services/item_service.dart';
import 'package:ecolanka/services/request_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> itemJson(String id, {String status = 'available'}) => {
      'id': id,
      'donorId': 'donor1',
      'title': 'Books $id',
      'description': 'Grade 10',
      'categoryId': 'books',
      'condition': 'good',
      'images': <String>[],
      'district': 'Colombo',
      'city': 'Nugegoda',
      'status': status,
      'requestCount': 0,
      'createdAt': '2026-10-26T06:00:00.000Z',
    };

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('ApiAuthService (API sends the SMS, e.g. via httpSMS)', () {
    test('sign-in stores the session and sends the bearer token afterwards', () async {
      final seen = <http.Request>[];
      final client = MockClient((req) async {
        seen.add(req);
        switch (req.url.path) {
          case '/api/auth/send-code':
            return json({'sent': true});
          case '/api/auth/verify':
            expect(jsonDecode(req.body), {'phone': '+94770000001', 'code': '123456'});
            return json({'token': 'tok', 'uid': 'u1', 'phone': '+94770000001', 'hasProfile': true});
          case '/api/auth/logout':
            return json({'ok': true});
        }
        return json({'message': 'nope'}, 404);
      });
      final api = ApiClient(baseUrl: 'http://x/api', httpClient: client, prefs: prefs);
      final auth = ApiAuthService(api);

      expect(auth.currentUid, isNull);
      expect(await auth.sendCode('+94770000001'), isFalse);
      await auth.verifyCode('123456');
      expect(auth.currentUid, 'u1');

      await auth.signOut();
      expect(seen.last.headers['Authorization'], 'Bearer tok');
      expect(auth.currentUid, isNull);
    });

    test('wrong code and SMS failures give friendly messages', () async {
      final client = MockClient((req) async => req.url.path.endsWith('send-code')
          ? json({'sent': true})
          : json({'message': 'Incorrect code. Please check and try again.', 'code': 'invalid-verification-code'}, 422));
      final auth = ApiAuthService(ApiClient(baseUrl: 'http://x/api', httpClient: client, prefs: prefs));
      await auth.sendCode('+94770000001');
      try {
        await auth.verifyCode('000000');
        fail('should throw');
      } catch (e) {
        expect(auth.isInvalidCode(e), isTrue);
        expect(auth.messageFor(e), 'Incorrect code. Please check and try again.');
      }

      final offline = ApiAuthService(ApiClient(
        baseUrl: 'http://x/api',
        httpClient: MockClient((_) async => json(
            {'message': 'We could not send the SMS right now. Please try again in a minute.', 'code': 'sms-failed'}, 503)),
        prefs: prefs,
      ));
      try {
        await offline.sendCode('+94771234567');
        fail('should throw');
      } catch (e) {
        expect(offline.messageFor(e), contains('could not send the SMS'));
      }
    });
  });

  group('ApiClient session', () {
    test('saveSession / restoreSession / clearSession and bearer header', () async {
      final seen = <http.Request>[];
      final client = MockClient((req) async {
        seen.add(req);
        return json({'ok': true});
      });
      final api = ApiClient(baseUrl: 'http://x/api', httpClient: client, prefs: prefs);
      expect(api.hasSession, isFalse);
      await api.saveSession(token: 'tok', uid: 'u1', phone: '+94770000001');

      final restored = ApiClient(baseUrl: 'http://x/api', httpClient: client, prefs: prefs);
      await restored.restoreSession();
      expect(restored.uid, 'u1');
      expect(restored.phone, '+94770000001');

      await restored.post('/auth/logout');
      expect(seen.last.headers['Authorization'], 'Bearer tok');

      await restored.clearSession();
      expect(restored.hasSession, isFalse);
      expect(prefs.getString('api_token'), isNull);
    });

    test('API errors become ApiException with the server message', () async {
      final client = MockClient((req) async =>
          json({'message': 'Sign-in could not be verified. Please try again.', 'code': 'invalid-id-token'}, 401));
      final api = ApiClient(baseUrl: 'http://x/api', httpClient: client, prefs: prefs);
      await expectLater(
        api.post('/auth/firebase', {'idToken': 'bad'}),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'invalid-id-token')
            .having((e) => e.statusCode, 'status', 401)),
      );
    });
  });

  group('ApiClient.watch', () {
    test('emits on first fetch, skips unchanged data, refetches after a write', () async {
      var status = 'available';
      var gets = 0;
      final client = MockClient((req) async {
        if (req.method == 'GET') {
          gets++;
          return json([itemJson('a', status: status)]);
        }
        status = 'reserved';
        return json({'ok': true});
      });
      final api = ApiClient(baseUrl: 'http://x/api', httpClient: client, prefs: prefs);
      final items = ApiItemService(api);

      final values = <List<Item>>[];
      final sub = items.latestItems().listen(values.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(values, hasLength(1));
      expect(values.single.single.status, 'available');

      api.notifyChanged(); // same JSON → no new event
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(values, hasLength(1));

      await items.setStatus('a', 'reserved'); // a write triggers a refetch
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(values, hasLength(2));
      expect(values.last.single.status, 'reserved');
      expect(gets, 3);
      await sub.cancel();
    });

    test('can be listened to more than once (like Firestore snapshots)', () async {
      final client = MockClient((req) async => json([itemJson('a')]));
      final api = ApiClient(baseUrl: 'http://x/api', httpClient: client, prefs: prefs);
      final stream = ApiItemService(api).latestItems();
      expect((await stream.first).single.id, 'a');
      expect((await stream.first).single.id, 'a');
    });

    test('404 becomes null for single documents', () async {
      final client = MockClient((req) async => json({'message': 'Not found.', 'code': 'not-found'}, 404));
      final api = ApiClient(baseUrl: 'http://x/api', httpClient: client, prefs: prefs);
      expect(await ApiItemService(api).watchItem('missing').first, isNull);
      expect(await ApiRequestService(api).getRequest('x_y'), isNull);
    });
  });

  test('new item ids are 20 url-safe characters', () {
    final api = ApiClient(baseUrl: 'http://x/api', httpClient: MockClient((_) async => json({})), prefs: prefs);
    final id = ApiItemService(api).newItemId();
    expect(id, matches(RegExp(r'^[A-Za-z0-9]{20}$')));
  });

  test('Item.fromJson / toNewJson', () {
    final item = Item.fromJson(itemJson('abc'));
    expect(item.createdAt, isNotNull);
    expect(item.toNewJson()['id'], 'abc');
    expect(item.toNewJson().containsKey('status'), isFalse);
  });
}
