import 'package:flutter/material.dart';
import '/services/language_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en', 'US');

  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final languageCode = await LanguageService.getLanguageCode();
    _locale = LanguageService.getLocale(languageCode);
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    LanguageService.setLanguageCode(locale.languageCode);
    notifyListeners();
  }
}