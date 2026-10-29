part of '../prayers.dart';

class PrayerNowWidget extends StatelessWidget {
  const PrayerNowWidget({super.key});

  // final adhanCtrl = AdhanController.instance;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdhanController>(
      id: 'init_athan',
      builder: (adhanCtrl) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0).r,
          child: Stack(
            children: [
              Obx(() {
                int currentPrayer = adhanCtrl.currentPrayerIndex;
                final prayerList = adhanCtrl.prayerNameList;
                if (prayerList.isEmpty ||
                    currentPrayer < 0 ||
                    currentPrayer >= prayerList.length) {
                  return const SizedBox.shrink();
                }
                return AnimatedRadialGauge(
                  /// The animation duration.
                  duration: const Duration(seconds: 1),
                  curve: Curves.elasticOut,

                  /// Define the radius.
                  /// If you omit this value, the parent size will be used, if possible.
                  radius: context.customOrientation(
                    Get.width * .48,
                    Get.width * .22,
                  ),

                  /// Gauge value.
                  value: adhanCtrl.getPrayerDayProgress.value,

                  onEnd: () => Get.forceAppUpdate(),

                  /// Optionally, you can configure your gauge, providing additional
                  /// styles and transformers.
                  axis: GaugeAxis(
                    /// Provide the [min] and [max] value for the [value] argument.
                    min: 0,
                    max: 100,

                    /// Render the gauge as a 180-degree arc.
                    sweepDegrees: 200,

                    /// Set the background color and axis thickness.
                    style: GaugeAxisStyle(
                      thickness: 30.h,
                      background: context.theme.colorScheme.primaryContainer,
                      zoneSpacing: 10,
                      cornerRadius: const Radius.circular(8.0),
                    ),
                    pointer: GaugePointer.circle(
                      radius: 8,
                      color: context.theme.canvasColor,
                    ),

                    /// Define the progress bar (optional).
                    progressBar: GaugeProgressBar.basic(
                      color: context.theme.colorScheme.surface.withValues(
                        alpha: .9,
                      ),
                      placement: GaugeProgressPlacement.inside,
                    ),

                    /// Define axis segments (optional).
                    zones: adhanCtrl.getPrayerGaugeSegments,
                  ),
                  builder: (context, child, value) => Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Icon(
                        prayerList[currentPrayer]['icon'],
                        size: 130.h,
                        color:
                            currentPrayer == 1 ||
                                currentPrayer == 2 ||
                                currentPrayer == 3 ||
                                currentPrayer == 4
                            ? const Color.fromARGB(
                                255,
                                242,
                                181,
                                15,
                              ).withValues(alpha: .1)
                            : context.theme.colorScheme.inversePrimary
                                  .withValues(alpha: .05),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${prayerList[currentPrayer]['title']}'.tr,
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 26.sp.clamp(26, 36),
                                fontWeight: FontWeight.bold,
                                color: context.theme.colorScheme.inversePrimary,
                                height: .2,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          ReactiveNumberText(
                            text: prayerList[currentPrayer]['time'],
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 26.sp.clamp(26, 36),
                              fontWeight: FontWeight.bold,
                              color: context.theme.colorScheme.inversePrimary,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.end,
                          ),
                          Container(
                            height: 45.h,
                            decoration: BoxDecoration(
                              color: context.theme.colorScheme.surface
                                  .withValues(alpha: .4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SlideCountdownWidget(
                                key: ValueKey<int>(currentPrayer),
                                fontSize: 34.sp,
                                color: context.theme.colorScheme.inversePrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(
                height: 35,
                child: CustomButton(
                  onPressed: () => context.customBottomSheet(
                    containerColor: context.theme.colorScheme.primaryContainer,
                    textTitle: 'sharePrayerTime',
                    child: ShareOptionsWidget(),
                  ),
                  width: 40,
                  iconSize: 28,
                  isCustomSvgColor: true,
                  svgPath: SvgPath.svgShareShare,
                  svgColor: context.theme.colorScheme.surface,
                  borderColor: context.theme.colorScheme.surface.withValues(
                    alpha: .3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
