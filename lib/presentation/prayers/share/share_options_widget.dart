part of '../prayers.dart';

class ShareOptionsWidget extends StatefulWidget {
  const ShareOptionsWidget({super.key});

  @override
  State<ShareOptionsWidget> createState() => _ShareOptionsWidgetState();
}

class _ShareOptionsWidgetState extends State<ShareOptionsWidget> {
  final shareCtrl = ShareController.instance;

  @override
  void initState() {
    super.initState();
    shareCtrl.startProgressTicker();
  }

  @override
  void dispose() {
    shareCtrl.stopProgressTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // البيانات تُحسب خارج Obx لأن getTimeNowColor يكتب في Rx أثناء البناء.
    // Data is computed outside Obx because getTimeNowColor writes an Rx value.
    final data = shareCtrl.cardData;

    return Obx(() {
      final design = shareCtrl.selectedDesign.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Gap(4),
            ShareDesignPicker(
              selected: design,
              onSelected: shareCtrl.selectDesign,
            ),
            const Gap(16),
            _buildPreview(context, design, data),
            const Gap(16),
            _buildShareButton(context),
            const Gap(8),
          ],
        ),
      );
    });
  }

  /// معاينة البطاقة المختارة مع تحديث شريط التقدّم لحظيًا.
  /// Preview of the selected card with a live-updating progress bar.
  Widget _buildPreview(
    BuildContext context,
    ShareCardDesign design,
    ShareCardData data,
  ) {
    return Obx(() {
      final progress = shareCtrl.progress.value;
      return ShareCardPreview(
        design: design,
        data: data.copyWith(progress: progress),
      );
    });
  }

  /// زر المشاركة.
  /// Share button.
  Widget _buildShareButton(BuildContext context) {
    final accent = context.theme.colorScheme.inversePrimary;
    return Obx(
      () => ContainerButtonWidget(
        onPressed: shareCtrl.isSaving.value
            ? null
            : () async {
                await shareCtrl.createAndShowVerseImage();
                await shareCtrl.shareAsImage();
              },
        height: 56,
        horizontalMargin: 0.0,
        borderRadius: 16,
        backgroundColor: context.theme.colorScheme.surface.withValues(
          alpha: .3,
        ),
        useGradient: false,
        title: 'shareImage'.tr,
        isLoading: shareCtrl.isSaving.value,
        svgPath: SvgPath.svgShareShare,
        svgHeight: 24,
        svgColor: accent,
        titleColor: accent,
        fontSize: 16,
      ),
    );
  }
}
