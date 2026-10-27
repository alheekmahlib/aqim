import 'dart:convert' show jsonDecode;
import 'dart:io' show Directory;

import 'package:aqim/core/widgets/container_button_widget.dart';
import 'package:aqim/presentation/feedback/controller/feedback_controller.dart';
import 'package:aqim/presentation/feedback/screens/feedback_thread_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// شاشة الملاحظات: حالة الفراغ + فتح ورقة الإرسال من الزر العائم
/// + تعطّل زر الإرسال دون نص أو مرفقات.
/// بلا tokens محفوظة لا يصدر أي طلب شبكة — الاختبار محلي بالكامل،
/// والترجمات تُحمَّل من ملف ar.json الحقيقي (نفس منطق dependency_inj).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> arStrings;

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/locales/ar.json');
    final mapped = jsonDecode(raw) as Map<String, dynamic>;
    arStrings = mapped.map((k, v) => MapEntry(k, v.toString()));
  });

  setUp(() async {
    Get.reset();

    // GetStorage يعتمد path_provider — نحاكي قناته بمجلد مؤقت.
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          return Directory.systemTemp.path;
        });

    await GetStorage.init();
    await GetStorage().remove('feedback_tokens');
    Get.put(FeedbackController(), permanent: true);
  });

  testWidgets('empty state renders, sheet opens, submit disabled', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (_, child) => GetMaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          translations: Messages(ar: arStrings),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const FeedbackThreadScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1) حالة الفراغ بالنص العربي المترجم من ملف الترجمة الحقيقي.
    expect(find.text(arStrings['feedbackNoNotesYet']!), findsOneWidget);

    // 2) فتح ورقة الإرسال من الزر العائم.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // 3) حقلا الرسالة والبريد ظاهران.
    expect(find.byType(TextField), findsNWidgets(2));

    // 4) زر الإرسال داخل الورقة (الأخير — الأول لزر حالة الفراغ) معطّل.
    final sheetButton = tester.widget<ContainerButtonWidget>(
      find.byType(ContainerButtonWidget).last,
    );
    expect(sheetButton.onPressed, isNull);
  });
}

/// غلاف ترجمات يوافق بنية Messages في التطبيق بلغة واحدة.
class Messages extends Translations {
  Messages({required this.ar});
  final Map<String, String> ar;

  @override
  Map<String, Map<String, String>> get keys => {'ar': ar};
}
