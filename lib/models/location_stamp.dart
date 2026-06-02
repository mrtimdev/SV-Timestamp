import 'app_settings.dart';

class LocationStamp {
  const LocationStamp({
    this.latitude,
    this.longitude,
    this.street = '',
    this.province = '',
    this.commune = '',
    this.district = '',
    this.village = '',
    this.city = '',
    this.country = '',
  });
  final double? latitude, longitude;
  final String street, province, commune, district, village, city, country;
  String get latitudeText => latitude?.toStringAsFixed(4) ?? '--';
  String get longitudeText => longitude?.toStringAsFixed(4) ?? '--';

  List<String> addressLinesFor(AppSettings settings) {
    final khmer = settings.language == AppLanguage.khmer;
    final details = <(bool, String, String)>[
      (settings.showStreet, khmer ? 'ផ្លូវ' : 'Street', street),
      (settings.showProvince, khmer ? 'ខេត្ត' : 'Province', province),
      (settings.showCommune, khmer ? 'ឃុំ/សង្កាត់' : 'Commune', commune),
      (settings.showDistrict, khmer ? 'ស្រុក/ខណ្ឌ' : 'District', district),
      (settings.showVillage, khmer ? 'ភូមិ' : 'Village', village),
      (settings.showCity, khmer ? 'ក្រុង' : 'City', city),
      (settings.showCountry, khmer ? 'ប្រទេស' : 'Country', country),
    ];
    final seen = <String>{};
    final lines = <String>[];
    for (final (visible, label, value) in details) {
      final clean = value.trim();
      if (visible && clean.isNotEmpty && seen.add(clean.toLowerCase())) {
        lines.add('$label: $clean');
      }
    }
    if (lines.isEmpty) {
      return [khmer ? 'មិនអាចរកទីតាំងបាន' : 'Location unavailable'];
    }
    return lines;
  }
}
