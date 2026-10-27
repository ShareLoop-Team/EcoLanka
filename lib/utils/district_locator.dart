// Geospatial engine (SRP): district centres, distance between districts and
// "which district am I in?" from GPS coordinates. Pure Dart, so it is unit
// tested without a device (test/domain_test.dart).

import 'dart:math' as math;

class GeoPoint2 {
  final double lat;
  final double lng;

  const GeoPoint2(this.lat, this.lng);
}

class DistrictLocator {
  DistrictLocator._();

  /// Approximate centre of each of Sri Lanka's 25 districts.
  static const Map<String, GeoPoint2> centres = {
    'Colombo': GeoPoint2(6.9271, 79.8612),
    'Gampaha': GeoPoint2(7.0873, 80.0144),
    'Kalutara': GeoPoint2(6.5854, 79.9607),
    'Kandy': GeoPoint2(7.2906, 80.6337),
    'Matale': GeoPoint2(7.4675, 80.6234),
    'Nuwara Eliya': GeoPoint2(6.9497, 80.7891),
    'Galle': GeoPoint2(6.0535, 80.2210),
    'Matara': GeoPoint2(5.9549, 80.5550),
    'Hambantota': GeoPoint2(6.1241, 81.1185),
    'Jaffna': GeoPoint2(9.6615, 80.0255),
    'Kilinochchi': GeoPoint2(9.3803, 80.3770),
    'Mannar': GeoPoint2(8.9810, 79.9044),
    'Vavuniya': GeoPoint2(8.7542, 80.4982),
    'Mullaitivu': GeoPoint2(9.2671, 80.8142),
    'Batticaloa': GeoPoint2(7.7310, 81.6747),
    'Ampara': GeoPoint2(7.2975, 81.6820),
    'Trincomalee': GeoPoint2(8.5874, 81.2152),
    'Kurunegala': GeoPoint2(7.4863, 80.3647),
    'Puttalam': GeoPoint2(8.0362, 79.8283),
    'Anuradhapura': GeoPoint2(8.3114, 80.4037),
    'Polonnaruwa': GeoPoint2(7.9403, 81.0188),
    'Badulla': GeoPoint2(6.9934, 81.0550),
    'Monaragala': GeoPoint2(6.8728, 81.3507),
    'Ratnapura': GeoPoint2(6.6828, 80.3992),
    'Kegalle': GeoPoint2(7.2513, 80.3464),
  };

  /// Great-circle distance in kilometres (haversine formula).
  static double distanceKm(GeoPoint2 a, GeoPoint2 b) {
    const earthRadiusKm = 6371.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(b.lat - a.lat);
    final dLng = rad(b.lng - a.lng);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(a.lat)) *
            math.cos(rad(b.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(h));
  }

  /// District whose centre is closest to [point].
  static String nearestDistrict(GeoPoint2 point) {
    String best = 'Colombo';
    var bestKm = double.infinity;
    centres.forEach((name, centre) {
      final km = distanceKm(point, centre);
      if (km < bestKm) {
        bestKm = km;
        best = name;
      }
    });
    return best;
  }

  /// Approximate distance between two districts (0 if the same / unknown).
  static double districtDistanceKm(String from, String to) {
    final a = centres[from];
    final b = centres[to];
    if (a == null || b == null || from == to) return 0;
    return distanceKm(a, b);
  }

  /// "Same district", "≈ 35 km away" etc.
  static String distanceLabel(String from, String to) {
    if (from == to) return 'In your district';
    final km = districtDistanceKm(from, to);
    if (km == 0) return to;
    return '≈ ${km.round()} km away';
  }
}
