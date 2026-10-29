import 'package:aqim/presentation/prayers/features/data/local_adhan_playback_control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'stopping ends the session then stops both owners; repeat calls are safe',
    () async {
      final calls = <String>[];
      final control = LocalAdhanPlaybackControl(
        stopNativeService: () async => calls.add('service'),
        stopInAppPlayer: () async => calls.add('player'),
      );

      await control.stopCurrentAdhan();
      await control.stopCurrentAdhan();

      // المحوّل ينهي الجلسة (لا قناة في الاختبار فتُتجاهل بهدوء) ثم
      // يوقف المالكين معًا.
      expect(calls, ['service', 'player', 'service', 'player']);
    },
  );

  test('a failing stop step does not block the remaining owner', () async {
    final calls = <String>[];
    final control = LocalAdhanPlaybackControl(
      stopNativeService: () async {
        calls.add('service');
        throw StateError('service gone');
      },
      stopInAppPlayer: () async => calls.add('player'),
    );

    await control.stopCurrentAdhan();
    expect(calls, containsAll(['service', 'player']));
  });
}
