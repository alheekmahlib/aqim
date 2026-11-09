part of '../events.dart';

class AllCalculatingEventsWidget extends StatelessWidget {
  final eventsCtrl = EventController.instance;

  AllCalculatingEventsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          customSvgWithColor(
            'assets/svg/hijri/${eventsCtrl.hijriNow.hMonth}.svg',
            width: Get.width,
            color: Theme.of(context)
                .colorScheme
                .inversePrimary
                .withValues(alpha: .05),
          ),
          Column(mainAxisSize: MainAxisSize.max, children: [
            const Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: eventsCtrl.isNewHadith
                              ? monthHadithsList[eventsCtrl.hijriNow.hMonth - 1]
                                  ['hadithPart1']
                              : monthHadithsList[1]['hadithPart1'],
                          style: TextStyle(
                            fontSize: 18.0,
                            fontFamily: 'naskh',
                            height: 1.9,
                            fontWeight: FontWeight.bold,
                            color: context.theme.colorScheme.inversePrimary
                                .withValues(alpha: .5),
                          ),
                        ),
                        TextSpan(
                          text: eventsCtrl.isNewHadith
                              ? monthHadithsList[eventsCtrl.hijriNow.hMonth - 1]
                                  ['hadithPart2']
                              : monthHadithsList[1]['hadithPart2'],
                          style: TextStyle(
                            fontSize: 18.0,
                            fontFamily: 'naskh',
                            height: 1.9,
                            fontWeight: FontWeight.bold,
                            color: context.theme.colorScheme.inversePrimary
                                .withValues(alpha: .8),
                          ),
                        ),
                        TextSpan(
                          text: eventsCtrl.isNewHadith
                              ? monthHadithsList[1]['bookName']
                              : monthHadithsList[eventsCtrl.hijriNow.hMonth - 1]
                                  ['bookName'],
                          style: TextStyle(
                            fontSize: 14.0,
                            fontFamily: 'naskh',
                            height: 1.7,
                            fontWeight: FontWeight.bold,
                            color: context.theme.colorScheme.inversePrimary
                                .withValues(alpha: .7),
                          ),
                        ),
                      ]),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const Gap(16.0),
                  context.hDivider(width: Get.width),
                ],
              ),
            ),
            Obx(() {
              if (eventsCtrl.events.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator.adaptive());
              } else {
                return ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: eventsCtrl.events.length,
                  itemBuilder: (context, i) {
                    // التحقق من وجود المناسبة في القائمة المطلوبة - Check if event exists in required list
                    if (!eventsCtrl.notReminderIndex
                        .contains(eventsCtrl.events[i].id)) {
                      return const SizedBox.shrink();
                    }

                    // حساب السنة المناسبة للمناسبة - Calculate appropriate year for the event
                    int eventYear = eventsCtrl.getEventYear(
                      eventsCtrl.events[i].month,
                      eventsCtrl.events[i].day.first,
                    );

                    return CalculatingDateEventsWidget(
                      name: eventsCtrl.events[i].title.tr,
                      year: eventYear,
                      month: eventsCtrl.events[i].month,
                      day: eventsCtrl.events[i].day.first,
                    );
                  },
                );
              }
            }),
            context.hDivider(width: Get.width),
            const Gap(16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'hijriNote'.tr,
                style: TextStyle(
                  fontSize: 14.0,
                  fontFamily: 'cairo',
                  height: 1.7,
                  color: context.theme.colorScheme.inversePrimary
                      .withValues(alpha: .7),
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const Gap(16.0),
          ]),
        ],
      ),
    );
  }
}
