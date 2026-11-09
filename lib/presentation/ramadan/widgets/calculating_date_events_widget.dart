part of '../events.dart';

class CalculatingDateEventsWidget extends StatelessWidget {
  final String name;
  final int year;
  final int month;
  final int day;
  CalculatingDateEventsWidget({
    super.key,
    required this.month,
    required this.day,
    required this.name,
    required this.year,
  });

  final countdownCtrl = EventController.instance;

  @override
  Widget build(BuildContext context) {
    // حساب الأيام المتبقية للحدث - Calculate remaining days for the event
    int daysRemaining = countdownCtrl.calculate(year, month, day);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 32.0),
      child: Opacity(
        opacity: daysRemaining == 0 ? .5 : 1,
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            // شريط التقدم الدائري - Rounded progress bar
            SingleChildScrollView(
              child: RoundedProgressBar(
                height: 35,

                style: RoundedProgressBarStyle(
                  borderWidth: 5,
                  widthShadow: 5,
                  backgroundProgress: Theme.of(context).primaryColorLight,
                  colorProgress: Theme.of(context).colorScheme.primary,
                  colorProgressDark: Theme.of(
                    context,
                  ).canvasColor.withValues(alpha: 0.5),
                  colorBorder: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.1),
                  colorBackgroundIcon: Colors.transparent,
                ),
                // margin: const EdgeInsets.symmetric(vertical: 2.0),
                borderRadius: BorderRadius.circular(4),
                percent: (1.0 - (daysRemaining / 355)) * 100,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        daysRemaining == 0 ? '$name: ${'hasPassed'.tr}' : name,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontFamily: 'cairo',
                          height: 1.7,
                          color: context.theme.canvasColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  daysRemaining == 0
                      ? const SizedBox.shrink()
                      : Expanded(
                          flex: 3,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ReactiveNumberText(
                              text: countdownCtrl.daysArabicConvert(
                                daysRemaining,
                                daysRemaining
                                    .toString()
                                    .convertNumbersToCurrentLang(),
                              ),
                              style: TextStyle(
                                fontSize: 14.0,
                                fontFamily: 'cairo',
                                height: 1.7,
                                color: context.theme.canvasColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
