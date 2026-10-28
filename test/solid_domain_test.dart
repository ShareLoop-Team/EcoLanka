// QA (Umayanga): SOLID domain classes from the Shareloop proposal.
import 'package:ecolanka/models/handover_method.dart';
import 'package:ecolanka/models/user_role.dart';
import 'package:ecolanka/utils/anti_resell_policy.dart';
import 'package:ecolanka/utils/district_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Interface Segregation — roles only get the capabilities they need', () {
    test('donor shares but does not request', () {
      final role = UserRole.fromId('donor');
      expect(role, isA<ItemDonor>());
      expect(role, isNot(isA<ItemRequester>()));
      expect(role, isNot(isA<PlatformModerator>()));
    });

    test('requester requests but does not share', () {
      final role = UserRole.fromId('requester');
      expect(role, isA<ItemRequester>());
      expect(role, isNot(isA<ItemDonor>()));
    });

    test('both / admin', () {
      expect(UserRole.fromId('both'), isA<ItemDonor>());
      expect(UserRole.fromId('both'), isA<ItemRequester>());
      expect(UserRole.fromId('admin'), isA<PlatformModerator>());
    });

    test('Liskov — every role is a valid UserRole and a viewer', () {
      for (final id in ['donor', 'requester', 'both', 'admin']) {
        final role = UserRole.fromId(id);
        expect(role.id, id);
        expect(role.label, isNotEmpty);
        expect(role, isA<ItemViewer>());
      }
    });

    test('users cannot pick admin themselves', () {
      expect(UserRole.selectable.map((r) => r.id), isNot(contains('admin')));
    });
  });

  group('Open/Closed — handover methods are interchangeable', () {
    test('all methods fulfil the same contract', () {
      for (final m in HandoverMethods.all) {
        expect(m.id, isNotEmpty);
        expect(m.title, isNotEmpty);
        expect(m.safetyTips(), isNotEmpty);
      }
    });

    test('lookup by id', () {
      expect(HandoverMethods.byId('courier'), isA<CourierDelivery>());
      expect(HandoverMethods.byId('on_demand'), isA<OnDemandDelivery>());
      expect(HandoverMethods.byId('nope'), isNull);
      expect(HandoverMethods.ids, ['direct', 'courier', 'on_demand']);
    });
  });

  group('Anti-resell policy', () {
    test('declaration text matches the proposal', () {
      expect(AntiResellPolicy.declaration,
          'I confirm that I will not resell this donated item.');
    });
    test('detects sale wording', () {
      expect(AntiResellPolicy.looksLikeSale('Rs. 1500 only'), isTrue);
      expect(AntiResellPolicy.looksLikeSale('Free school bag'), isFalse);
    });
  });

  group('District locator (geo engine)', () {
    test('nearest district from GPS', () {
      expect(DistrictLocator.nearestDistrict(const GeoPoint2(6.93, 79.85)), 'Colombo');
      expect(DistrictLocator.nearestDistrict(const GeoPoint2(7.29, 80.63)), 'Kandy');
      expect(DistrictLocator.nearestDistrict(const GeoPoint2(9.66, 80.02)), 'Jaffna');
    });

    test('distance between districts', () {
      expect(DistrictLocator.districtDistanceKm('Colombo', 'Colombo'), 0);
      final km = DistrictLocator.districtDistanceKm('Colombo', 'Kandy');
      expect(km, greaterThan(80));
      expect(km, lessThan(110));
      expect(DistrictLocator.distanceLabel('Galle', 'Galle'), 'In your district');
    });

    test('all 25 districts have a centre', () {
      expect(DistrictLocator.centres.length, 25);
    });
  });
}
