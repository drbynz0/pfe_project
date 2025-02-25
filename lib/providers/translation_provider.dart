import 'package:flutter/material.dart';
import '/services/translation_service.dart';

class TranslationProvider with ChangeNotifier {
  final TranslationService _translationService = TranslationService();
  Map<String, String> _translations = {};

  Map<String, String> get translations => _translations;

  Future<void> translateTexts(Map<String, String> texts, String targetLanguage) async {
    _translations = await _translationService.translateTexts(texts, targetLanguage);
    notifyListeners();
  }
}