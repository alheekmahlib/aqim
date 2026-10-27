import 'dart:async';

import 'package:aqim/core/widgets/custom_switch_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// CustomSwitchWidget: عرض متفائل فوري + سبينر بجوار المفتاح أثناء عمل
/// onChanged المتزامن/غير المتزامن + حجب النقرات المزدوجة + زوال السبينر
/// عند الاكتمال أو الخطأ.
class _FakeController extends GetxController {}

void main() {
  Widget wrap(Widget child) => GetMaterialApp(
    locale: const Locale('ar'),
    home: Scaffold(body: Center(child: child)),
  );

  CustomSwitchWidget<_FakeController> buildSwitch({
    required bool value,
    required Function(bool) onChanged,
  }) => CustomSwitchWidget<_FakeController>(
    controller: _FakeController(),
    value: value,
    onChanged: onChanged,
    title: 'testSwitch',
  );

  testWidgets('السبينر يظهر أثناء العمل والنقر الثاني محجوب حتى الاكتمال', (
    WidgetTester tester,
  ) async {
    final completer = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      wrap(
        buildSwitch(
          value: false,
          onChanged: (v) {
            calls++;
            return completer.future;
          },
        ),
      ),
    );

    await tester.tap(find.byType(CustomSwitch));
    await tester.pump();

    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(CustomSwitch));
    await tester.pump();
    expect(calls, 1, reason: 'النقر أثناء الانشغال يجب أن يُتجاهل');

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('عرض متفائل: القيمة تتغير فورًا قبل اكتمال onChanged', (
    WidgetTester tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      wrap(buildSwitch(value: false, onChanged: (_) => completer.future)),
    );

    CustomSwitch switchWidget() =>
        tester.widget<CustomSwitch>(find.byType(CustomSwitch));
    expect(switchWidget().value, isFalse);

    await tester.tap(find.byType(CustomSwitch));
    await tester.pump();

    expect(switchWidget().value, isTrue, reason: 'العرض المتفائل فوري');

    completer.complete();
    await tester.pumpAndSettle();
    // الأب لم يجدد القيمة (ويدجت ثابت في الاختبار) فيعود العرض للقيمة الفعلية
    expect(switchWidget().value, isFalse);
  });

  testWidgets('onChanged متزامن لا يعلّق السبينر', (WidgetTester tester) async {
    var calls = 0;
    await tester.pumpWidget(
      wrap(buildSwitch(value: false, onChanged: (v) => calls++)),
    );

    await tester.tap(find.byType(CustomSwitch));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('رمي onChanged يزيل السبينر ويعيد تفعيل النقر', (
    WidgetTester tester,
  ) async {
    final first = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      wrap(
        buildSwitch(
          value: false,
          onChanged: (v) {
            calls++;
            if (calls == 1) {
              return first.future.then((_) => throw Exception('boom'));
            }
            return Future<void>.value();
          },
        ),
      ),
    );

    await tester.tap(find.byType(CustomSwitch));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    first.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(CustomSwitch));
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'المفتاح يعمل من جديد بعد الخطأ');
  });
}
