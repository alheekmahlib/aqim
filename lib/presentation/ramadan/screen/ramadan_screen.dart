part of '../events.dart';

/// شاشة رمضان الشاملة
/// Comprehensive Ramadan screen
class RamadanScreen extends StatelessWidget {
  RamadanScreen({super.key});

  final eventsCtrl = EventController.instance;
  final ramadanCtrl = RamadanController.instance;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RamadanController>(
      init: ramadanCtrl,
      builder: (ctrl) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32, right: 16, left: 16),
          child: Column(
            children: [
              customSvgWithColor(
                'assets/svg/hijri/9.svg',
                width: 250,
                color: context.theme.colorScheme.surface,
              ),
              _sectionTitle(context, 'qadaSection'),
              const Gap(16),
              const QadaProgressWidget(),
              const Gap(16),
              const QadaCalendarWidget(),
              const Gap(20),
              _sectionTitle(context, 'quranSection'),
              const Gap(16),
              const QuranTrackerWidget(),
              const Gap(20),
              _sectionTitle(context, 'notificationsSection'),
              const Gap(16),
              const RamadanNotificationsSettings(),
            ],
          ),
        );
      },
    );
  }

  Row _sectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: context.theme.colorScheme.surface.withValues(alpha: .4),
            thickness: 1,
          ),
        ),
        const Gap(8),
        Text(
          title.tr,
          style: TextStyle(
            height: 1.4,
            fontSize: 16,
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.inversePrimary.withValues(
              alpha: .6,
            ),
          ),
        ),
        const Gap(8),
        Expanded(
          child: Divider(
            color: context.theme.colorScheme.surface.withValues(alpha: .4),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
