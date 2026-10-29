import 'package:aqim/core/utils/helpers/app_themes.dart';
import 'package:aqim/presentation/prayers/features/data/custom_adhan_selector.dart';
import 'package:aqim/presentation/prayers/features/domain/custom_adhan_repository.dart';
import 'package:aqim/presentation/prayers/features/domain/local_adhan_audio.dart';
import 'package:aqim/presentation/prayers/features/presentation/custom_adhan_controller.dart';
import 'package:aqim/presentation/prayers/features/presentation/widgets/custom_adhan_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'feature_test_translations.dart';

class _FakeRepository implements CustomAdhanRepository {
  final audios = <LocalAdhanAudio>[
    const LocalAdhanAudio(
      id: 'a1',
      name: 'مؤذن الحي',
      duration: Duration(seconds: 125),
      audioPath: '/durable/a1.mp3',
    ),
  ];

  @override
  Future<List<LocalAdhanAudio>> list() async => List.of(audios);

  @override
  Future<LocalAdhanAudio> importAudio({
    required String sourcePath,
    required String name,
  }) async => throw UnimplementedError();

  @override
  Future<void> rename(String id, String name) async {}

  @override
  Future<void> delete(String id) async {
    audios.removeWhere((audio) => audio.id == id);
  }
}

class _FakeSelector implements CustomAdhanSelector {
  _FakeSelector(this.activeId);

  String activeId;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #activeAudioId) return activeId;
    throw UnimplementedError();
  }
}

Widget host(Widget child, {double scale = 1}) => GetMaterialApp(
  locale: const Locale('ar'),
  translations: FeatureTestTranslations(),
  theme: blueTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    backgroundColor: blueTheme.colorScheme.primaryContainer,
    body: SingleChildScrollView(child: child),
  ),
);

void main() {
  testWidgets('custom muezzin section fits at 2x text, 320px', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = CustomAdhanController(
      repository: _FakeRepository(),
      selector: _FakeSelector('a1'),
      pickAudioFile: () async => null,
      reschedule: () async {},
      selectStandardAdhan: (_) async {},
      probeForPreview: (_) async => const Duration(seconds: 125),
    );
    await controller.load();

    await tester.pumpWidget(
      host(CustomAdhanSection(controller: controller), scale: 2),
    );
    await tester.pumpAndSettle();

    expect(find.text('مؤذن مخصص'), findsOneWidget);
    expect(find.text('مؤذن الحي'), findsOneWidget);
    expect(find.text('2:05'), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-a1')), findsOneWidget);
    expect(find.byKey(const ValueKey('rename-a1')), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-a1')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-adhan-import')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
