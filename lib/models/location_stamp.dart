import 'app_settings.dart';

class LocationStamp {
  const LocationStamp({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.street = '',
    this.province = '',
    this.commune = '',
    this.district = '',
    this.village = '',
    this.city = '',
    this.country = '',
  });
  final double? latitude, longitude, accuracy;
  final String street, province, commune, district, village, city, country;
  String get latitudeText => latitude?.toStringAsFixed(4) ?? '--';
  String get longitudeText => longitude?.toStringAsFixed(4) ?? '--';

  List<String> addressLinesFor(AppSettings settings) {
    final khmer = settings.language == AppLanguage.khmer;
    final values = <(bool, String)>[
      (settings.showStreet, street),
      (settings.showProvince, province),
      (settings.showCommune, commune),
      (settings.showDistrict, district),
      (settings.showVillage, village),
      (settings.showCity, city),
      (settings.showCountry, country),
    ];
    final seen = <String>{};
    final parts = <String>[];
    for (final (visible, value) in values) {
      final clean = value.trim();
      if (visible && clean.isNotEmpty && seen.add(clean.toLowerCase())) {
        parts.add(clean);
      }
    }
    if (parts.isEmpty) {
      return [khmer ? 'មិនអាចរកទីតាំងបាន' : 'Location unavailable'];
    }
    return [parts.join(', ')];
  }
}
