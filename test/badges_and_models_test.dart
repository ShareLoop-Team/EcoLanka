// QA (Umayanga): achievement tiers, user model, formatters, lookups.
import 'package:ecolanka/models/badge.dart';
import 'package:ecolanka/models/user.dart';
import 'package:ecolanka/utils/formatters.dart';
import 'package:ecolanka/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AchievementEngine (Bronze 5 · Silver 10 · Gold 25 · Platinum 50)', () {
    test('no tier below 5 donations', () {
      expect(AchievementEngine.currentTier(0), isNull);
      expect(AchievementEngine.currentTier(4), isNull);
      expect(AchievementEngine.nextTier(4)!.id, 'bronze');
    });

    test('tier thresholds', () {
      expect(AchievementEngine.currentTier(5)!.id, 'bronze');
      expect(AchievementEngine.currentTier(10)!.id, 'silver');
      expect(AchievementEngine.currentTier(24)!.id, 'silver');
      expect(AchievementEngine.currentTier(25)!.id, 'gold');
      expect(AchievementEngine.currentTier(50)!.id, 'platinum');
      expect(AchievementEngine.currentTier(120)!.level, 'Community Champion');
      expect(AchievementEngine.nextTier(50), isNull);
    });

    test('progress to next tier', () {
      expect(AchievementEngine.progressToNext(0), 0);
      expect(AchievementEngine.progressToNext(5), 0); // just reached bronze
      expect(AchievementEngine.progressToNext(15), closeTo(1 / 3, 0.001)); // 10 → 25
      expect(AchievementEngine.progressToNext(60), 1);
    });

    test('badge list marks earned tiers', () {
      final badges = AchievementEngine.badges(12);
      expect(badges.where((b) => b.earned).map((b) => b.id), ['bronze', 'silver']);
    });

    test('eco points = 10 per donation + 2 per request', () {
      expect(AchievementEngine.ecoPoints(donations: 3, requests: 4), 38);
    });
  });

  group('AppUser', () {
    test('fromMap applies defaults', () {
      final u = AppUser.fromMap('u1', {'displayName': 'Nimal'});
      expect(u.role, 'both');
      expect(u.district, 'Colombo');
      expect(u.donationCount, 0);
      expect(u.canDonate, isTrue);
      expect(u.canRequest, isTrue);
    });

    test('role permissions', () {
      const donor = AppUser(uid: 'a', displayName: 'A', role: 'donor', language: 'en', district: 'Galle');
      const requester = AppUser(uid: 'b', displayName: 'B', role: 'requester', language: 'si', district: 'Kandy');
      const banned = AppUser(uid: 'c', displayName: 'C', role: 'both', language: 'en', district: 'Kandy', isBanned: true);
      expect(donor.canDonate, isTrue);
      expect(donor.canRequest, isFalse);
      expect(requester.canDonate, isFalse);
      expect(requester.canRequest, isTrue);
      expect(banned.canDonate, isFalse);
      expect(banned.canRequest, isFalse);
    });

    test('monthly donations only count for the current month', () {
      const u = AppUser(
          uid: 'x', displayName: 'X', role: 'both', language: 'en', district: 'Galle',
          monthKey: '2026-10', monthDonations: 3);
      expect(u.donationsInMonth('2026-10'), 3);
      expect(u.donationsInMonth('2026-11'), 0);
      expect(AppUser.monthKeyFor(DateTime.utc(2026, 10, 18)), '2026-10');
    });

    test('toMap → fromMap round trip', () {
      const u = AppUser(uid: 'x', displayName: 'Kavidu', role: 'both', language: 'ta', district: 'Jaffna', donationCount: 4);
      final back = AppUser.fromMap('x', u.toMap());
      expect(back.displayName, 'Kavidu');
      expect(back.language, 'ta');
      expect(back.donationCount, 4);
    });
  });

  group('Formatters', () {
    final now = DateTime(2026, 10, 18, 12);
    test('timeAgo', () {
      expect(Formatters.timeAgo(null), 'just now');
      expect(Formatters.timeAgo(now.subtract(const Duration(minutes: 5)), now: now), '5 min ago');
      expect(Formatters.timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3 h ago');
      expect(Formatters.timeAgo(now.subtract(const Duration(days: 2)), now: now), '2 d ago');
      expect(Formatters.timeAgo(DateTime(2026, 9, 1), now: now), '1 Sep 2026');
    });
    test('phone', () {
      expect(Formatters.phone('+94771234567'), '+94 77 123 4567');
      expect(Formatters.phone(null), '');
    });
  });

  group('Lookups (Shareloop documentation)', () {
    test('7 categories from the docs; unknown falls back to Other', () {
      expect(AppCategories.all.length, 7);
      expect(AppCategories.byId('books').name, 'Educational Books');
      expect(AppCategories.byId('nope').id, 'other');
    });
    test('conditions New / Good / Used', () {
      expect(AppConditions.labels.values, ['New', 'Good', 'Used']);
    });
    test('25 districts', () {
      expect(AppDistricts.all.length, 25);
    });
  });
}
