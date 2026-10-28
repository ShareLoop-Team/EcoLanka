// GPS implementation of LocationProvider (geolocator).
// Only coarse location is needed: we turn it into the nearest district.

import 'package:geolocator/geolocator.dart';

import '../repositories/repositories.dart';
import '../utils/district_locator.dart';

class GeolocatorLocationService implements LocationProvider {
  @override
  Future<GeoPoint2> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location services are turned off. Please turn them on.';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw 'Location permission was denied. You can still pick a district manually.';
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
      timeLimit: const Duration(seconds: 15),
    );
    return GeoPoint2(position.latitude, position.longitude);
  }
}
