part of '../events.dart';

class ReminderEventBottomSheet extends StatelessWidget {
  final String lottieFile;
  final String title;
  final String hadith;
  final String bookInfo;
  final String titleString;
  final String svgPath;
  final int? day;
  final int? month;
  ReminderEventBottomSheet({
    super.key,
    required this.lottieFile,
    required this.title,
    required this.hadith,
    required this.bookInfo,
    required this.titleString,
    required this.svgPath,
    this.day,
    this.month,
  });

  // final generalCtrl = GeneralController.instance;
  final eventCtrl = EventController.instance;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                headerWidget(context),
                bodyWidget(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget headerWidget(BuildContext context) {
    return Container(
        width: Get.width,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(
              color: context.theme.canvasColor,
              width: 2,
            )),
        child: eventCtrl.getArtWidget(
          ramadanOrEid(lottieFile, width: 200),
          customSvgWithColor(svgPath,
              color: context.theme.canvasColor, width: 200, height: 200),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              titleString,
              style: TextStyle(
                color: context.theme.canvasColor,
                fontFamily: 'cairo',
                fontWeight: FontWeight.bold,
                fontSize: 60,
                height: 3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          day!,
          month!,
        ));
  }

  Widget bodyWidget(BuildContext context) {
    return Column(
      children: [
        Container(
          width: Get.width,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
              color: context.theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              )),
          child: Text(
            title.tr,
            style: TextStyle(
              color: context.theme.colorScheme.primary,
              fontFamily: 'cairo',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
              color: context.theme.canvasColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              )),
          child: ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            children: [
              const Gap(8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      children: hadith.buildTextSpans(),
                      style: TextStyle(
                        color: context.theme.colorScheme.onInverseSurface,
                        fontFamily: 'naskh',
                        fontSize: 22,
                        height: 1.7,
                      ),
                    ),
                    WidgetSpan(child: context.hDivider(width: Get.width)),
                    TextSpan(
                      text: bookInfo,
                      style: TextStyle(
                        color: context.theme.colorScheme.onInverseSurface,
                        fontFamily: 'naskh',
                        fontSize: 17,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        )
      ],
    );
  }
}
