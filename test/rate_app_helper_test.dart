import 'package:aqim/core/utils/helpers/rate_app_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_store_review/multi_store_review.dart';
import 'package:multi_store_review_platform_interface/multi_store_review_platform_interface.dart';

/// منصة وهمية تحاكي تخزين المنصة وتسجّل محاولات التقييم وفتح المتجر.
class _FakePlatform extends MultiStoreReviewPlatform {
  bool canReview = true;
  ReviewGateState state = ReviewGateState.empty;
  int reviewRequests = 0;
  int listingOpens = 0;
  StoreListing? lastListing;

  @override
  Future<ReviewStore?> detectStore() async =>
      canReview ? ReviewStore.appleAppStore : null;

  @override
  Future<ReviewStore> requestReview({ReviewStore? store}) async {
    reviewRequests++;
    return ReviewStore.appleAppStore;
  }

  @override
  Future<void> openStoreListing(StoreListing listing) async {
    listingOpens++;
    lastListing = listing;
  }

  @override
  Future<ReviewGateState> readReviewGateState() async => state;

  @override
  Future<void> writeReviewGateState(ReviewGateState value) async =>
      state = value;
}

/// يصفّي المهام المؤجلة حتى تكتمل استدعاءات initReviewGate النارية.
Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakePlatform platform;

  setUp(() async {
    platform = _FakePlatform();
    MultiStoreReviewPlatform.instance = platform;
    await MultiStoreReview.instance.resetReviewGate();
  });

  group('RateAppHelper.initReviewGate', () {
    test('يعدّ إطلاقًا واحدًا مهما نودي مرارًا في الجلسة نفسها', () async {
      RateAppHelper.initReviewGate();
      await _flushMicrotasks();
      expect(platform.state.launches, 1);
      expect(platform.state.firstLaunchAt, greaterThan(0));

      RateAppHelper.initReviewGate();
      await _flushMicrotasks();
      expect(platform.state.launches, 1);
    });

    test('البوابة مغلقة قبل 7 إطلاقات', () async {
      RateAppHelper.initReviewGate();
      await _flushMicrotasks();

      platform.state = platform.state.copyWith(launches: 6);
      expect(await RateAppHelper.maybeRequestReview(), isFalse);
      expect(platform.reviewRequests, 0);
    });
  });

  group('RateAppHelper.maybeRequestReview', () {
    test(
      'يطلب الحوار الأصلي عند اكتمال 7 إطلاقات ثم يلتزم فترة 15 يومًا',
      () async {
        RateAppHelper.initReviewGate();
        await _flushMicrotasks();
        platform.state = platform.state.copyWith(launches: 7);

        expect(await RateAppHelper.maybeRequestReview(), isTrue);
        expect(platform.reviewRequests, 1);
        expect(platform.state.lastPromptAt, greaterThan(0));

        // المحاولة الفورية التالية تُرفض بسبب المهلة بين الطلبات.
        expect(await RateAppHelper.maybeRequestReview(), isFalse);
        expect(platform.reviewRequests, 1);
      },
    );

    test('يفتح صفحة المتجر كحل بديل عندما لا يتوفر حوار أصلي', () async {
      platform.canReview = false;
      RateAppHelper.initReviewGate();
      await _flushMicrotasks();
      platform.state = platform.state.copyWith(launches: 7);

      expect(await RateAppHelper.maybeRequestReview(), isTrue);
      expect(platform.reviewRequests, 0);
      expect(platform.listingOpens, 1);
      expect(platform.lastListing?.appStoreId, '6752765521');
    });
  });
}
