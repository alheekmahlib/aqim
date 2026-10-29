import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';

class FeatureTestTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    for (final language in ['ar', 'en'])
      language:
          (jsonDecode(File('assets/locales/$language.json').readAsStringSync())
                  as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, value.toString())),
  };
}
