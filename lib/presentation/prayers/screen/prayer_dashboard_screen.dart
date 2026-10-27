import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:solar_icons/solar_icons.dart';

import '/core/services/location/locations.dart';
import '/core/utils/constants/extensions/bottom_sheet_extension.dart';
import '/core/utils/helpers/app_router.dart';
import '/core/widgets/active_location_button.dart';
import '/core/widgets/reactive_number_text.dart';
import '/presentation/calendar/events.dart';
import '/presentation/controllers/general/general_controller.dart';
import '/presentation/prayers/prayers.dart';
import '/presentation/qibla/qibla.dart';
import '../../../core/utils/constants/extensions/convert_number_extension.dart';

/// شاشة الصلاة بتصميم "لوحة القياس" — بديلة لـ [PrayerScreen] وليست بدلاً عنها.
///
/// - لا تحتوي أي حسابات: كل القيم من [AdhanController] و[QiblaController]
///   و[EventController] و[Location].
/// - الألوان كلها من `Theme.of(context).colorScheme` فتتبع ثيم التطبيق
///   (فاتح/داكن) دون أي لون ثابت.
/// - فقط العدّاد يُعاد بناؤه كل ثانية.
class PrayerDashboardScreen extends StatelessWidget {
  const PrayerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final generalCtrl = GeneralController.instance;
    final palette = _Palette.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) return;
        PrayersNotificationsCtrl.instance.state.adhanPlayer.stop();
        Get.back();
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.backgroundTop, palette.background],
            ),
          ),
          child: SafeArea(
            child:
                !generalCtrl.state.activeLocation.value ||
                    LocationHelper.instance.locationIsEmpty
                ? ActiveLocationButton()
                : GetBuilder<AdhanController>(
                    id: 'loading_state',
                    builder: (ctrl) =>
                        ctrl.isLoadingPrayerData.value ||
                            ctrl.isNoInternetAndDataNotInitialized.value
                        ? const LoadingWidget()
                        : const _DashboardBody(),
                  ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Palette ─────────────────────────────

/// ألوان مشتقة من ثيم التطبيق فقط.
class _Palette {
  _Palette._(this.scheme);
  final ColorScheme scheme;

  factory _Palette.of(BuildContext context) =>
      _Palette._(Theme.of(context).colorScheme);

  /// لون التطبيق المميّز (الأخضر الرمادي) — يحل محل اللون الإبرازي.
  Color get accent => scheme.surface;
  Color get background => scheme.primaryContainer;
  Color get backgroundTop => Color.alphaBlend(
    scheme.inversePrimary.withValues(alpha: .05),
    scheme.primaryContainer,
  );
  Color get text => scheme.inversePrimary;
  Color get muted => scheme.inversePrimary.withValues(alpha: .55);
  Color get panel => scheme.inversePrimary.withValues(alpha: .04);
  Color get border => scheme.inversePrimary.withValues(alpha: .12);
  Color get divider => scheme.inversePrimary.withValues(alpha: .10);
}

const _fontFamily = 'cairo';

// ───────────────────────────── Body ─────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 700;
        final content = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Gap(12),
                const _Header(),
                Gap(wide ? 40 : 28),
                const _Hero(),
                Gap(wide ? 40 : 28),
                const _ScheduleStrip(),
                const Gap(16),
                const _LocationQiblaPanel(),
                const Gap(24),
              ],
            ),
          ),
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 14),
                    child: child,
                  ),
                ),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────────── Header ─────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final hijri = EventController.instance.hijriNow;
    final lang = Get.locale?.languageCode ?? 'ar';
    final now = DateTime.now();

    final hijriText = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}'
        .convertNumbersToCurrentLang();
    final gregorianText = intl.DateFormat('d MMMM y', lang).format(now);

    return Row(
      children: [
        Expanded(
          child: Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hijriText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                    height: 1.3,
                  ),
                ),
                const Gap(2),
                Text(
                  gregorianText.convertNumbersToCurrentLang(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 12.5,
                    color: p.muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Gap(12),
        _CircleAction(
          icon: Icons.calendar_today_outlined,
          label: 'calendar'.tr,
          onTap: () => context.customBottomSheet(
            containerColor: p.background,
            textTitle: 'calendar',
            child: const _DatePickerSheet(),
          ),
        ),
        const Gap(8),
        _CircleAction(
          icon: SolarIconsOutline.settings,
          label: 'prayerSetting'.tr,
          onTap: () => context.customBottomSheet(
            containerColor: p.background,
            textTitle: 'prayerSetting',
            child: const PrayerSettings(),
          ),
        ),
      ],
    );
  }
}

/// زر دائري رفيع الحدود، حجمه 44 للّمس.
class _CircleAction extends StatefulWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_CircleAction> createState() => _CircleActionState();
}

class _CircleActionState extends State<_CircleAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? .92 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: p.border, width: 1),
              color: _pressed ? p.panel : Colors.transparent,
            ),
            child: Icon(widget.icon, size: 20, color: p.text),
          ),
        ),
      ),
    );
  }
}

/// اختيار تاريخ آخر لعرض أوقاته — يستخدم نفس دالة الشاشة الأصلية.
class _DatePickerSheet extends StatelessWidget {
  const _DatePickerSheet();

  @override
  Widget build(BuildContext context) {
    final adhanCtrl = AdhanController.instance;
    final p = _Palette.of(context);
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        height: 84,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 15,
          separatorBuilder: (_, __) => const Gap(8),
          itemBuilder: (context, i) {
            final date = DateTime(
              today.year,
              today.month,
              today.day,
            ).add(Duration(days: i - 7));
            final selected =
                date.year == adhanCtrl.state.selectedDate.year &&
                date.month == adhanCtrl.state.selectedDate.month &&
                date.day == adhanCtrl.state.selectedDate.day;
            final lang = Get.locale?.languageCode ?? 'ar';
            return GestureDetector(
              onTap: () async {
                adhanCtrl.state.selectedDate = date;
                await adhanCtrl.updateSelectedDate(date);
                Get.back();
              },
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: selected ? p.accent : Colors.transparent,
                  border: Border.all(color: selected ? p.accent : p.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      intl.DateFormat('E', lang).format(date),
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 12,
                        color: selected ? p.background : p.muted,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '${date.day}'.convertNumbersToCurrentLang(),
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: selected ? p.background : p.text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────────── Hero ─────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);

    return GetBuilder<AdhanController>(
      id: 'init_athan',
      builder: (adhanCtrl) {
        final list = adhanCtrl.prayerNameList;
        final index = adhanCtrl.currentPrayerIndex;
        if (list.isEmpty || index < 0 || index >= list.length) {
          return const SizedBox(height: 220);
        }
        final name = '${list[index]['title']}'.tr;
        final subtitle = 'timeLeft:'.tr.replaceAll(RegExp(r'\s*[:：]\s*$'), '');

        return Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, .25),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey<int>(index),
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: p.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: p.accent.withValues(alpha: .6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const Gap(10),
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: p.text,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 14,
                      color: p.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),
            _LiveCountdown(
              key: ValueKey<int>(index),
              onElapsed: () {
                // انتقال الصلاة/منتصف الليل: نفس سلوك الشاشة الأصلية.
                adhanCtrl.update(['init_athan']);
                Get.forceAppUpdate();
              },
            ),
          ],
        );
      },
    );
  }
}

/// العدّاد: وحده يُعاد بناؤه كل ثانية، ويقرأ الزمن المتبقي من المتحكم
/// نفسه (يتعامل مع الفجر التالي ومنتصف الليل).
class _LiveCountdown extends StatefulWidget {
  const _LiveCountdown({super.key, required this.onElapsed});
  final VoidCallback onElapsed;

  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  final _adhanCtrl = AdhanController.instance;
  late final ValueNotifier<Duration> _left;
  Timer? _timer;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _left = ValueNotifier(_read());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Duration _read() {
    final d = _adhanCtrl.state.prayerTimes == null
        ? Duration.zero
        : _adhanCtrl.getTimeLeftForNextPrayer;
    return d.isNegative ? Duration.zero : d;
  }

  void _tick() {
    final d = _read();
    _left.value = d;
    if (d.inSeconds <= 0 && !_fired) {
      _fired = true;
      widget.onElapsed();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _left.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Transform.scale(
      scaleX: 1.0,
      scaleY: 1.8,
      child: RepaintBoundary(
        child: ValueListenableBuilder<Duration>(
          valueListenable: _left,
          builder: (context, d, _) {
            String two(int n) => n.toString().padLeft(2, '0');
            final hm = '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:'
                .convertNumbersToCurrentLang();
            final ss = two(
              d.inSeconds.remainder(60),
            ).convertNumbersToCurrentLang();

            const size = 76.0;
            const base = TextStyle(
              fontFamily: _fontFamily,
              fontSize: size,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -2,
              fontFeatures: [FontFeature.tabularFigures()],
            );

            return Semantics(
              label:
                  '${d.inHours} : ${d.inMinutes.remainder(60)} : ${d.inSeconds.remainder(60)}',
              excludeSemantics: true,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: hm,
                          style: base.copyWith(color: p.text),
                        ),
                        TextSpan(
                          text: ss,
                          style: base.copyWith(
                            color: p.accent,
                            shadows: [
                              Shadow(
                                color: p.accent.withValues(alpha: .45),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────────── Schedule ─────────────────────────────

/// الأعمدة الستة بترتيبها الزمني: الفجر، الشروق، الظهر، العصر، المغرب، العشاء.
/// الفهارس تطابق `prayerNameList` (0..5)؛ منتصف الليل والثلث الأخير لا يُعرضان.
const _scheduleIcons = <IconData>[
  SolarIconsOutline.moonFog,
  SolarIconsOutline.sunrise,
  SolarIconsOutline.sun,
  SolarIconsOutline.sun2,
  SolarIconsOutline.sunset,
  SolarIconsOutline.moon,
];

class _ScheduleStrip extends StatelessWidget {
  const _ScheduleStrip();

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);

    return GetBuilder<AdhanController>(
      id: 'init_athan',
      builder: (adhanCtrl) {
        final list = adhanCtrl.prayerNameList;
        if (list.length < 6) return const SizedBox.shrink();

        // بعد العشاء (٦ و٧: منتصف الليل/الثلث الأخير) تبقى العشاء هي المميّزة.
        final raw = adhanCtrl.currentPrayerIndex;
        final active = raw > 5 ? 5 : raw;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: p.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (int i = 0; i < 6; i++) ...[
                  Expanded(
                    child: _ScheduleCell(
                      icon: _scheduleIcons[i],
                      title: '${list[i]['title']}'.tr,
                      time: '${list[i]['time']}',
                      active: i == active,
                      isSolarEvent: i == 1,
                    ),
                  ),
                  if (i < 5)
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      indent: 6,
                      endIndent: 6,
                      color: p.divider,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScheduleCell extends StatelessWidget {
  const _ScheduleCell({
    required this.icon,
    required this.title,
    required this.time,
    required this.active,
    required this.isSolarEvent,
  });
  final IconData icon;
  final String title;
  final String time;
  final bool active;
  final bool isSolarEvent;

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final color = active ? p.accent : p.text;
    final sub = active ? p.accent : p.muted;

    return Semantics(
      container: true,
      selected: active,
      label: '$title $time',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [p.accent.withValues(alpha: .14), Colors.transparent],
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? p.accent : p.muted),
            const Gap(8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  // الشروق حدث شمسي لا صلاة: أخفت قليلاً.
                  color: isSolarEvent && !active ? p.muted : color,
                  height: 1.2,
                ),
              ),
            ),
            const Gap(4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: ReactiveNumberText(
                text: time,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sub,
                  height: 1.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const Gap(10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              height: 2,
              width: active ? 22 : 0,
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Location + Qibla ─────────────────────────────

class _LocationQiblaPanel extends StatelessWidget {
  const _LocationQiblaPanel();

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            const Expanded(flex: 11, child: _LocationSection()),
            VerticalDivider(width: 1, thickness: 1, color: p.divider),
            const Expanded(flex: 9, child: _QiblaSection()),
          ],
        ),
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection();

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final adhanCtrl = AdhanController.instance;
    final generalCtrl = GeneralController.instance;

    return Semantics(
      button: true,
      label: 'updateLocation'.tr,
      child: InkWell(
        borderRadius: const BorderRadiusDirectional.horizontal(
          start: Radius.circular(18),
        ).resolve(Directionality.of(context)),
        onTap: () async {
          final ok = await generalCtrl.updateLocationAndPrayerTimes();
          if (ok) Get.forceAppUpdate();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<String>(
            future: adhanCtrl.localizedLocation,
            builder: (context, snap) {
              final parts = (snap.data ?? '')
                  .split('\n')
                  .where((e) => e.trim().isNotEmpty)
                  .toList();
              final city = parts.isNotEmpty ? parts.first : '';
              final country = parts.length > 1 ? parts[1] : '';
              final stored = QiblaController.instance.getStoredLocation;
              final coords = stored == null
                  ? ''
                  : '${stored.latitude.toStringAsFixed(3)}°, '
                        '${stored.longitude.toStringAsFixed(3)}°';

              return Row(
                children: [
                  Icon(Icons.place_outlined, size: 22, color: p.muted),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                            height: 1.3,
                          ),
                        ),
                        if (country.isNotEmpty)
                          Text(
                            country,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 12,
                              color: p.muted,
                              height: 1.3,
                            ),
                          ),
                        if (coords.isNotEmpty)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              coords.convertNumbersToCurrentLang(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 11,
                                color: p.muted.withValues(alpha: .8),
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QiblaSection extends StatelessWidget {
  const _QiblaSection();

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final qiblaCtrl = QiblaController.instance;

    return Semantics(
      button: true,
      label: 'qiblaDirection'.tr,
      child: InkWell(
        borderRadius: const BorderRadiusDirectional.horizontal(
          end: Radius.circular(18),
        ).resolve(Directionality.of(context)),
        onTap: () => Get.toNamed(AppRouter.qiblaScreen),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Obx(() {
                  final deg = qiblaCtrl.qiblaDirection.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'qiblaDirection'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 12,
                          color: p.muted,
                          height: 1.3,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '${deg.toStringAsFixed(1)}°'
                              .convertNumbersToCurrentLang(),
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: p.text,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const Gap(8),
              Obx(
                () => _CompassDial(
                  bearing: qiblaCtrl.qiblaDirection.value,
                  color: p.accent,
                  needle: p.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بوصلة مصغّرة: حلقة بلون التطبيق وإبرة تشير إلى زاوية القبلة (من الشمال).
class _CompassDial extends StatelessWidget {
  const _CompassDial({
    required this.bearing,
    required this.color,
    required this.needle,
  });
  final double bearing;
  final Color color;
  final Color needle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: .25), blurRadius: 12),
              ],
            ),
          ),
          Transform.rotate(
            angle: bearing * math.pi / 180,
            child: CustomPaint(
              size: const Size(44, 44),
              painter: _NeedlePainter(color: color, tail: needle),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  _NeedlePainter({required this.color, required this.tail});
  final Color color;
  final Color tail;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    final head = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + 4, c.dy)
      ..lineTo(c.dx - 4, c.dy)
      ..close();
    final back = Path()
      ..moveTo(c.dx, c.dy + r * .7)
      ..lineTo(c.dx + 4, c.dy)
      ..lineTo(c.dx - 4, c.dy)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
    canvas.drawPath(back, Paint()..color = tail.withValues(alpha: .35));
    canvas.drawCircle(c, 2, Paint()..color = tail);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) =>
      old.color != color || old.tail != tail;
}
