import 'package:aqim/presentation/prayers/features/data/face_down_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime t(int seconds, [int millis = 0]) => DateTime(
    2026,
    10,
    29,
    12,
  ).add(Duration(seconds: seconds, milliseconds: millis));

  test('requires a face-up transition before a stable face-down stop', () {
    final detector = FaceDownDetector(
      stability: const Duration(milliseconds: 1200),
    );
    // مقلوب منذ البداية: لا انتقال → لا توقف.
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(0))), isFalse);
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(2))), isFalse);

    // انتقال للأعلى ثم انقلاب مستقر.
    expect(detector.offer(AccelerometerSample(z: 9.5, at: t(3))), isFalse);
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(4))), isFalse);
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(5))), isFalse);
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(6, 500))), isTrue);
  });

  test('gray-zone samples reset the stability window', () {
    final detector = FaceDownDetector(
      stability: const Duration(milliseconds: 1200),
    );
    expect(detector.offer(AccelerometerSample(z: 9.5, at: t(0))), isFalse);
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(1))), isFalse);
    // مستوى أفقي يقطع الاستقرار قبل اكتمال المدة.
    expect(detector.offer(AccelerometerSample(z: 0.5, at: t(2))), isFalse);
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(3))), isFalse);
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(4))), isFalse);
    // نافذة جديدة بدأت من t(3)؛ t(4) لم تكتمل بعد.
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(4, 900))), isTrue);
  });

  test('fires once per flip and rearms', () {
    final detector = FaceDownDetector(
      stability: const Duration(milliseconds: 1000),
    );
    expect(detector.offer(AccelerometerSample(z: 9.5, at: t(0))), isFalse);
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(1))), isFalse);
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(3))), isTrue);
    // بقاء مقلوبًا بعد التوقف لا يعيد الإطلاق.
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(10))), isFalse);
    // قلب جديد كامل يسلح مرة أخرى.
    expect(detector.offer(AccelerometerSample(z: 9.5, at: t(11))), isFalse);
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(12))), isFalse);
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(14))), isTrue);
  });

  test('reset clears the transition memory', () {
    final detector = FaceDownDetector();
    expect(detector.offer(AccelerometerSample(z: 9.5, at: t(0))), isFalse);
    detector.reset();
    expect(detector.offer(AccelerometerSample(z: -9.5, at: t(5))), isFalse);
  });
}
