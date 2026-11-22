part of '../prayers.dart';

/// التصاميم المتاحة لبطاقة مشاركة وقت الصلاة.
/// Available designs for the prayer-time share card.
enum ShareCardDesign {
  /// بطاقة زجاجية فوق تدرّج الوقت (التصميم الأصلي).
  classic,

  /// جدول بأوقات اليوم مع تمييز الصلاة القادمة.
  timetable,

  /// بطاقة عمودية بنسبة 9:16 مناسبة للستوري.
  story;

  /// مفتاح الترجمة المستخدمة في واجهة اختيار التصميم.
  /// Localization key used by the design picker UI.
  String get labelKey =>
      'shareDesign${name[0].toUpperCase()}${name.substring(1)}';

  /// العرض المنطقي للبطاقة عند التصدير (قبل مضاعفة الدقة).
  /// Logical width used when exporting the card.
  double get exportWidth => this == ShareCardDesign.story ? 360 : 400;

  /// الارتفاع المنطقي للبطاقة عند التصدير، أو null للارتفاع الطبيعي.
  /// Logical height used when exporting the card, or null for natural height.
  double? get exportHeight => this == ShareCardDesign.story ? 640 : null;

  /// هل التصميم عمودي (9:16)؟
  /// Whether the design uses a vertical 9:16 format.
  bool get isVertical => this == ShareCardDesign.story;

  /// أيقونة التصميم في شريط الاختيار.
  /// Icon representing the design in the picker.
  IconData get icon => switch (this) {
    ShareCardDesign.classic => Icons.auto_awesome_rounded,
    ShareCardDesign.timetable => Icons.grid_on_rounded,
    ShareCardDesign.story => Icons.auto_stories_rounded,
  };
}

/// عنصر صلاة واحد داخل جدول اليوم.
class SharePrayerSlot {
  final String name;
  final String time;
  final bool isNext;

  const SharePrayerSlot({
    required this.name,
    required this.time,
    this.isNext = false,
  });
}

/// كل البيانات التي تحتاجها أي تصميم ليرسم نفسه.
/// All data required by any design to render itself.
class ShareCardData {
  /// اسم الصلاة القادمة (مترجم مسبقًا).
  final String prayerName;

  /// وقت الصلاة القادمة (نص جاهز مثل ٦:٢٨ م).
  final String prayerTime;

  /// عنوان "الصلاة القادمة" (مترجم مسبقًا).
  final String nextPrayerLabel;

  /// عنوان الوقت المتبقي (مترجم مسبقًا).
  final String timeLeftTitle;

  /// قيمة الوقت المتبقي (نص جاهز مثل ٠٢:٥٤ س).
  final String timeLeftValue;

  /// التاريخ الهجري كاملًا.
  final String hijriDate;

  /// اسم اليوم.
  final String weekday;

  /// المدينة / الموقع.
  final String location;

  /// اسم التطبيق.
  final String appName;

  /// عنوان جدول الأوقات (مترجم مسبقًا).
  final String prayerTimesTitle;

  /// نسبة اليوم المنقضية بين الصلاة الحالية والقادمة (0..1).
  final double progress;

  /// أوقات اليوم كاملة (للتصميم الذي يعرض جدولًا).
  final List<SharePrayerSlot> prayers;

  /// التدرّج اللوني المعتمد على وقت اليوم.
  final LinearGradient gradient;

  /// رقم الشهر الهجري (١..١٢) لاختيار أيقونة الهلال.
  final int hijriMonth;

  const ShareCardData({
    required this.prayerName,
    required this.prayerTime,
    required this.nextPrayerLabel,
    required this.timeLeftTitle,
    required this.timeLeftValue,
    required this.hijriDate,
    required this.weekday,
    required this.location,
    required this.appName,
    required this.prayerTimesTitle,
    required this.progress,
    required this.prayers,
    required this.gradient,
    this.hijriMonth = 5,
  });

  /// نسخة معدّلة من البيانات (تُستخدم لتحديث نسبة التقدّم فقط).
  /// A copy of the data with updated values (used to refresh the progress).
  ShareCardData copyWith({double? progress, LinearGradient? gradient}) {
    return ShareCardData(
      prayerName: prayerName,
      prayerTime: prayerTime,
      nextPrayerLabel: nextPrayerLabel,
      timeLeftTitle: timeLeftTitle,
      timeLeftValue: timeLeftValue,
      hijriDate: hijriDate,
      weekday: weekday,
      location: location,
      appName: appName,
      prayerTimesTitle: prayerTimesTitle,
      progress: progress ?? this.progress,
      prayers: prayers,
      gradient: gradient ?? this.gradient,
      hijriMonth: hijriMonth,
    );
  }
}

/// ألوان مشتركة بين التصاميم.
class _Palette {
  static const Color ink = Color(0xFF16211C);
}

/// نقطة دخول واحدة تبدّل بين التصاميم.
/// Single entry point that switches between the available designs.
class ShareCardView extends StatelessWidget {
  final ShareCardDesign design;
  final ShareCardData data;

  const ShareCardView({super.key, required this.design, required this.data});

  @override
  Widget build(BuildContext context) {
    switch (design) {
      case ShareCardDesign.classic:
        return _ClassicShareCard(data: data);
      case ShareCardDesign.timetable:
        return _TimetableShareCard(data: data);
      case ShareCardDesign.story:
        return _StoryShareCard(data: data);
    }
  }
}

// ---------------------------------------------------------------------------
// عناصر مشتركة
// ---------------------------------------------------------------------------

/// معاينة بطاقة المشاركة داخل ورقة المشاركة.
///
/// تعرض البطاقة المختارة بحجم أصغر دون تغيير تخطيطها الداخلي، فتبقى
/// مطابقة تمامًا للصورة التي ستُصدَّر عند المشاركة.
///
/// Renders the selected card scaled down for the share sheet without changing
/// its internal layout, so it stays identical to the exported image.
class ShareCardPreview extends StatelessWidget {
  final ShareCardDesign design;
  final ShareCardData data;

  /// أقصى ارتفاع للمعاينة العمودية (9:16) داخل الورقة.
  final double maxVerticalHeight;

  const ShareCardPreview({
    super.key,
    required this.design,
    required this.data,
    this.maxVerticalHeight = 430,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;

        if (design.isVertical) {
          // التصميم العمودي بمقاس ثابت؛ يُصغَّر بصريًا فقط دون تغيير تخطيطه.
          const naturalW = 360.0;
          const naturalH = 640.0;
          final scale = math.min(
            available / naturalW,
            maxVerticalHeight / naturalH,
          );
          return Center(
            child: SizedBox(
              width: naturalW * scale,
              height: naturalH * scale,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: naturalW,
                  maxWidth: naturalW,
                  minHeight: naturalH,
                  maxHeight: naturalH,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: naturalW,
                      height: naturalH,
                      child: ShareCardView(design: design, data: data),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Center(
          child: SizedBox(
            width: design.exportWidth,
            child: ShareCardView(design: design, data: data),
          ),
        );
      },
    );
  }
}

/// شريط تقدّم بسيط بحدود ونهاية مستديرة.
class ShareProgressBar extends StatelessWidget {
  final double progress;

  const ShareProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return RoundedProgressBar(
      height: 25,
      style: RoundedProgressBarStyle(
        borderWidth: 5,
        widthShadow: 5,
        backgroundProgress: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.1),
        colorProgress: Theme.of(context).canvasColor,
        colorProgressDark: Theme.of(
          context,
        ).colorScheme.inversePrimary.withValues(alpha: 0.1),
        colorBorder: Theme.of(context).canvasColor.withValues(alpha: 0.1),
        colorBackgroundIcon: Colors.transparent,
      ),
      // margin: EdgeInsets.symmetric(vertical: 16),
      borderRadius: BorderRadius.circular(6),
      percent: progress * 100,
    );
  }
}

/// هلال الشهر الهجري كعلامة مائية في أعلى البطاقة.
class _HijriCrescent extends StatelessWidget {
  final int month;
  final Color? color;
  final double height;
  final double alpha;

  const _HijriCrescent({
    required this.month,
    this.color,
    this.height = 48,
    this.alpha = .4,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/hijri/${month.clamp(1, 12)}.svg',
      height: height,
      colorFilter: ColorFilter.mode(
        (color ?? Colors.white).withValues(alpha: alpha),
        BlendMode.srcIn,
      ),
    );
  }
}

/// شعار التطبيق داخل بطاقة المشاركة.
class _ShareLogo extends StatelessWidget {
  final Color color;
  final double height;

  const _ShareLogo({required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    return customSvgWithCustomColor(
      SvgPath.svgLogoAqemLogo,
      height: height,
      color: color,
    );
  }
}
