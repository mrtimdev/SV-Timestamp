import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/location_stamp.dart';

class LocationService {
  Future<LocationStamp> locate({required String localeIdentifier}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationStamp();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationStamp();
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      var stamp = LocationStamp(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      try {
        await setLocaleIdentifier(localeIdentifier);
        final places = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (places.isNotEmpty) {
          final p = places.first;
          stamp = LocationStamp(
            latitude: position.latitude,
            longitude: position.longitude,
            street: p.street ?? p.thoroughfare ?? '',
            province: p.administrativeArea ?? '',
            commune: p.subLocality ?? '',
            district: p.subAdministrativeArea ?? '',
            village: p.name ?? '',
            city: p.locality ?? '',
            country: p.country ?? '',
          );
        }
      } catch (_) {}
      return stamp;
    } catch (_) {
      return const LocationStamp();
    }
  }
}
