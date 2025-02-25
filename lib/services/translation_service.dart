import 'package:translator/translator.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  Future<String> translate(String text, String targetLanguage) async {
    final translation = await _translator.translate(text, to: targetLanguage);
    return translation.text;
  }

  Future<Map<String, String>> translateTexts(Map<String, String> texts, String targetLanguage) async {
    final translatedTexts = <String, String>{};
    for (var entry in texts.entries) {
      translatedTexts[entry.key] = await translate(entry.value, targetLanguage);
    }
    return translatedTexts;
  }
}