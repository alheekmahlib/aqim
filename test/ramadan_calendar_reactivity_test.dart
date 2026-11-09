import 'dart:io';

import 'package:aqim/presentation/ramadan/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hijri_date/hijri_date.dart';
import 'package:solar_icons/solar_icons.dart';

class _CalendarController extends RamadanController {
  // The fake avoids initializing unrelated notification and storage services.
  @override
  // ignore: must_call_super
  void onInit() {
    hijriNow = HijriDate.now();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDirectory;
  setUpAll(() async {
    storageDirectory = await Directory.systemTemp.createTemp(
      'ramadan_calendar_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => storageDirectory.path,
        );
    await GetStorage.init();
  });
  tearDown(Get.reset);
  tearDownAll(() async {
    await storageDirectory.delete(recursive: true);
  });

  testWidgets('calendar builds and reacts to missed and fasted days', (
    tester,
  ) async {
    final controller = Get.put<RamadanController>(_CalendarController());
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: QadaCalendarWidget()),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byIcon(SolarIconsBold.closeCircle), findsNothing);
    expect(find.byIcon(SolarIconsBold.checkCircle), findsNothing);

    final day = QadaDay(day: 1, month: 9, year: controller.hijriNow.hYear);
    controller.missedDays.add(day);
    await tester.pump();
    expect(find.byIcon(SolarIconsBold.closeCircle), findsOneWidget);

    controller.fastedDays.add(day);
    await tester.pump();
    expect(find.byIcon(SolarIconsBold.closeCircle), findsNothing);
    expect(find.byIcon(SolarIconsBold.checkCircle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
