import '../../models/app_settings.dart';

class AppStrings {
  const AppStrings(this.language);
  final AppLanguage language;
  bool get isKhmer => language == AppLanguage.khmer;
  String text(String english, String khmer) => isKhmer ? khmer : english;
  String get localeIdentifier => isKhmer ? 'km_KH' : 'en_US';
  String get languageCode => isKhmer ? 'km' : 'en';
}
