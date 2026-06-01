import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider extends ChangeNotifier {
  static const String _langKey = 'selected_language';

  String _currentLocale = 'ru';
  Map<String, String> _localizedStrings = {};
  bool _isLoaded = false;

  String get currentLocale => _currentLocale;
  bool get isLoaded => _isLoaded;
  Map<String, String> get l10n => _localizedStrings;  // Геттер для переводов

  String get currentLanguageName {
    switch (_currentLocale) {
      case 'en': return 'English';
      case 'ru': return 'Русский';
      case 'tj': return 'Тоҷикӣ';
      default: return 'Русский';
    }
  }

  String get currentLanguageFlag {
    switch (_currentLocale) {
      case 'en': return '🇬🇧';
      case 'ru': return '🇷🇺';
      case 'tj': return '🇹🇯';
      default: return '🇷🇺';
    }
  }

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'tj', 'name': 'Тоҷикӣ', 'flag': '🇹🇯'},
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocale = prefs.getString(_langKey) ?? 'ru';
    await _loadLanguage(_currentLocale);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> switchLanguage(String langCode) async {
    if (_currentLocale == langCode) return;
    _currentLocale = langCode;
    await _loadLanguage(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, langCode);
    notifyListeners();
  }

  Future<void> _loadLanguage(String langCode) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/l10n/$langCode.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonStr);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      _localizedStrings = {};
      debugPrint('Failed to load language $langCode: $e');
    }
  }

  String tr(String key, {Map<String, String>? params}) {
    String text = _localizedStrings[key] ?? key;
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        text = text.replaceAll('{$paramKey}', paramValue);
      });
    }
    return text;
  }

  String categoryName(String categoryKey) {
    return tr('category_$categoryKey');
  }

  String statusName(String statusKey) {
    return tr('task_status_$statusKey');
  }
}
