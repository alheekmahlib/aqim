part of '../teaching.dart';

class TeachingPrayerScreen extends StatelessWidget {
  const TeachingPrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TeachingPrayerController.instance; // ensure init
    final ctrl = TeachingPrayerController.instance;
    final eventCtrl = EventController.instance;
    final currentMonth = eventCtrl.hijriNow.hMonth;
    final controller = FloatingMenuExpendableController();

    return Scaffold(
      backgroundColor: context.theme.colorScheme.surface.withValues(alpha: .1),
      body: SafeArea(
        child: Container(
          color: context.theme.colorScheme.primaryContainer,
          child: GestureDetector(
            onTap: () => controller.close(),
            child: Column(
              children: [
                const AppBarWidget(withBackButton: false),
                GetBuilder<TeachingPrayerController>(
                  id: 'loading_state',
                  builder: (_) => ctrl.isLoading.value
                      ? Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: context.theme.colorScheme.surface,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      GetBuilder<TeachingPrayerController>(
                        id: 'content_state',
                        builder: (_) {
                          final sections = ctrl.sections;
                          if (sections.isEmpty && !ctrl.isLoading.value) {
                            return Expanded(
                              child: Center(
                                child: Text(
                                  'noData'.trParams({'x': 'TeachingPrayer'}),
                                  style: TextStyle(
                                    color: context
                                        .theme
                                        .colorScheme
                                        .inversePrimary,
                                    fontFamily: 'cairo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView(
                            children: [
                              const Gap(16),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  customSvgWithColor(
                                    height: 180,
                                    SvgPath.svgHomeTeachingPrayer,
                                    color: context.theme.colorScheme.surface
                                        .withValues(alpha: .1),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(0, 10),
                                    child: Column(
                                      children: [
                                        customSvgWithColor(
                                          height: 60,
                                          SvgPath.svgLiatafaqahuu,
                                          color:
                                              context.theme.colorScheme.surface,
                                        ),
                                        Text(
                                          'understanding'.tr,
                                          style: TextStyle(
                                            color: context
                                                .theme
                                                .colorScheme
                                                .inversePrimary
                                                .withValues(alpha: .9),
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'cairo',
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                itemCount: sections.length,
                                itemBuilder: (context, index) {
                                  final section = sections[index];
                                  final title = section.resolveName(
                                    ctrl.currentLang,
                                  );
                                  return _SectionCard(
                                    title: title,
                                    index: index,
                                  );
                                },
                              ),
                              const Gap(80),
                            ],
                          );
                        },
                      ),
                      FloatingMenuWidget(
                        ctrl: ctrl,
                        currentMonth: currentMonth,
                        controller: controller,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingMenuWidget extends StatelessWidget {
  const FloatingMenuWidget({
    super.key,
    required this.ctrl,
    required this.currentMonth,
    required this.controller,
  });

  final TeachingPrayerController ctrl;
  final int currentMonth;
  final FloatingMenuExpendableController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lang = ctrl.currentLang;
      final monthData = ctrl.getMonthData(currentMonth);
      final hadith = ctrl.getHadithForMonth(currentMonth);
      final sunnahs = ctrl.getSunnahsForMonth(currentMonth);
      final heresies = ctrl.getHeresiesForMonth(currentMonth);
      final isEmpty = hadith == null || monthData == null;
      // if (hadith == null || monthData == null) {
      //   return const SizedBox.shrink();
      // }
      return FloatingMenuExpendable(
        controller: controller,
        panelWidth: isEmpty ? 130 : 460,
        panelHeight: isEmpty ? 52 : 360,
        handleWidth: 130,
        handleHeight: 52,
        expandPanelFromHandle: true,
        initialPosition: const Offset(12, 12),
        openMode: FloatingMenuExpendableOpenMode.vertical,
        style: FloatingMenuExpendableStyle(
          // Background barrier
          showBarrierWhenOpen: isEmpty ? false : true,
          barrierDismissible: isEmpty ? false : true,
          barrierColor: context.theme.colorScheme.primaryContainer.withValues(
            alpha: 0.3,
          ),
          barrierBlurSigmaX: 10,
          barrierBlurSigmaY: 10,
          panelDecoration: BoxDecoration(
            color: context.theme.colorScheme.surface.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          // Panel
          panelBorderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        handleChild: ValueListenableBuilder<FloatingMenuPanelPhysicalSide?>(
          valueListenable: controller.physicalSide,
          builder: (context, horizontalSide, _) {
            return ValueListenableBuilder<FloatingMenuPanelPhysicalSide?>(
              valueListenable: controller.verticalSide,
              builder: (context, verticalSide, _) {
                final isRight =
                    horizontalSide == FloatingMenuPanelPhysicalSide.right;

                final sideForArrow = verticalSide ?? horizontalSide;

                final arrowAngle = switch (sideForArrow) {
                  FloatingMenuPanelPhysicalSide.top =>
                    isRight ? (math.pi / -.87) : (math.pi / -.73),
                  FloatingMenuPanelPhysicalSide.bottom =>
                    isRight ? (math.pi / -.42) : (math.pi / -.47),
                  _ => 0.0,
                };

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: isRight
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  children: [
                    Expanded(
                      child: HijriDateWidget(
                        alignment: Alignment.center,
                        svgColor: context.theme.colorScheme.surface,
                        horizontalPadding: 0.0,
                      ),
                    ),
                    const Gap(8),
                    Transform.rotate(
                      angle: arrowAngle,
                      child: customSvgWithColor(
                        'assets/svg/arrow_up.svg',
                        height: 20,
                        color: context.theme.colorScheme.surface,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        panelChild: isEmpty
            ? const SizedBox.shrink()
            : GlassContainer(
                radius: 8,
                variant: GlassVariant.opaque,
                child: DefaultTabController(
                  length:
                      hadith.isNotEmpty &&
                          sunnahs.isNotEmpty &&
                          heresies.isNotEmpty
                      ? 3
                      : hadith.isNotEmpty && sunnahs.isNotEmpty
                      ? 2
                      : hadith.isNotEmpty && heresies.isNotEmpty
                      ? 2
                      : heresies.isNotEmpty && sunnahs.isNotEmpty
                      ? 2
                      : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: TabBar(
                            indicatorColor: context.theme.colorScheme.surface,
                            labelColor: context.theme.colorScheme.surface,
                            unselectedLabelColor: context
                                .theme
                                .colorScheme
                                .surface
                                .withValues(alpha: .6),
                            tabs: [
                              if (hadith.isNotEmpty)
                                Tab(
                                  child: Text(
                                    'aboutMonth'.tr,
                                    style: const TextStyle(
                                      fontFamily: 'cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              if (sunnahs.isNotEmpty)
                                Tab(
                                  child: Text(
                                    _getLocalizedText('sunnahs', lang),
                                    style: const TextStyle(
                                      fontFamily: 'cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              if (heresies.isNotEmpty)
                                Tab(
                                  child: Text(
                                    _getLocalizedText('heresies', lang),
                                    style: const TextStyle(
                                      fontFamily: 'cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: context.theme.colorScheme.surface
                                  .withValues(alpha: .08),
                            ),
                            child: TabBarView(
                              children: [
                                if (hadith.isNotEmpty)
                                  SingleChildScrollView(
                                    child: _HadithCard(hadith: hadith),
                                  ),
                                if (sunnahs.isNotEmpty)
                                  const SunnahsAndHeresies(isSunnah: true),
                                if (heresies.isNotEmpty)
                                  const SunnahsAndHeresies(isSunnah: false),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      );
    });
  }

  static String _getLocalizedText(String key, String lang) {
    const Map<String, Map<String, String>> texts = {
      'sunnahs': {
        'ar': 'السُّنن',
        'en': 'Sunnahs',
        'tr': 'Sünnetler',
        'ur': 'سنتیں',
        'id': 'Sunnah',
        'ms': 'Sunnah',
        'bn': 'সুন্নাহ',
        'es': 'Sunnas',
      },
      'heresies': {
        'ar': 'البِدَع',
        'en': 'Innovations (Bid\'ah)',
        'tr': 'Bid\'atler',
        'ur': 'بدعات',
        'id': 'Bid\'ah',
        'ms': 'Bid\'ah',
        'bn': 'বিদ\'আত',
        'es': 'Innovaciones',
      },
    };
    return texts[key]?[lang] ?? texts[key]?['ar'] ?? key;
  }
}
