import 'package:aqim/core/services/languages/dependency_inj.dart' as dep;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the application translations', () async {
    final languages = await dep.init();
    expect(languages, isNotEmpty);
    expect(languages.values.every((translations) => translations.isNotEmpty), isTrue);
    expect(languages.keys.any((locale) => locale.startsWith('ar_')), isTrue);
    Get.reset();
  });
}
