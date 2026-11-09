import 'package:aqim/core/utils/constants/extensions/bottom_sheet_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('navigates between pages in one sheet and handles system back', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.customFamilyBottomSheet(
                textTitle: 'Settings',
                child: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => context.customPushToPage(
                      context: context,
                      textTitle: 'Section',
                      child: const Text('Section contents'),
                    ),
                    child: const Text('Open section'),
                  ),
                ),
              ),
              child: const Text('Open settings'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(find.text('Open section'), findsOneWidget);
    await tester.tap(find.text('Open section'));
    await tester.pumpAndSettle();
    expect(find.text('Section contents'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Open section'), findsOneWidget);
    expect(find.text('Section contents'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
