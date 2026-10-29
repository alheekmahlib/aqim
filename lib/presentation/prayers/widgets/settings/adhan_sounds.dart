part of '../../prayers.dart';

class AdhanSounds extends StatelessWidget {
  AdhanSounds({super.key});

  final notificationCtrl = PrayersNotificationsCtrl.instance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 37,
      child: ContainerButtonWidget(
        onPressed: () => customBottomSheet(
          textTitle: 'adhanSounds',
          child: bottomSheetWidget(context),
          containerColor: context.theme.colorScheme.primaryContainer,
        ),
        title: 'adhanSounds'.tr,
        titleColor: Theme.of(context).colorScheme.inversePrimary,
        width: Get.width,
        withShape: false,
        useGradient: false,
        borderRadius: 8.0,
        borderColor: Colors.transparent,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: .3),
        mainAxisAlignment: MainAxisAlignment.start,
      ),
    );
  }

  Widget bottomSheetWidget(BuildContext context) {
    return SizedBox(
      height: Get.height * .5,
      child: FutureBuilder<List<AdhanData>>(
        future: notificationCtrl.state.adhanData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final customAdhanEnabled = StoredPrayerFeatureSettings(
              GetStorage(),
            ).read()[PrayerFeature.customAdhan].enabled;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListView(
                children: [
                  if (customAdhanEnabled && Get.isRegistered<CustomAdhanController>())
                    CustomAdhanSection(
                      controller: Get.find<CustomAdhanController>(),
                    ),
                  ...List.generate(
                    snapshot.data!.length,
                    (index) => adhanListBuild(context, index),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
        },
      ),
    );
  }

  Widget adhanListBuild(BuildContext context, int index) {
    final notificationCtrl = PrayersNotificationsCtrl.instance;
    return FutureBuilder<List<AdhanData>>(
      future: notificationCtrl.state.adhanData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          List<AdhanData> adhans = snapshot.data!;
          return GetX<PrayersNotificationsCtrl>(
            builder: (notificationCtrl) {
              bool isSelected = notificationCtrl
                  .isAdhanSelectByIndex(index)
                  .value;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                  border: Border.all(
                    color: isSelected
                        ? context.theme.colorScheme.surface
                        : context.theme.colorScheme.surface.withValues(
                            alpha: .5,
                          ),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 10,
                      // Material بدل Container ملوّن حتى تظهر تموّجات نقر
                      // ListTile فوق الخلفية لا خلفها.
                      child: Material(
                        color: isSelected
                            ? context.theme.colorScheme.surface.withValues(
                                alpha: .5,
                              )
                            : context.theme.colorScheme.surface.withValues(
                                alpha: .2,
                              ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          minTileHeight: 40,
                          onTap: () async {
                            notificationCtrl.switchAdhanOnTap(index);
                            notificationCtrl
                                    .isAdhanDownloadedByIndex(index)
                                    .value
                                ? null
                                : await notificationCtrl.adhanDownload(
                                    adhans[index],
                                  );
                            await notificationCtrl.reschedulePrayers();
                          },
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                adhans[index].adhanName.tr,
                                style: TextStyle(
                                  color: context
                                      .theme
                                      .colorScheme
                                      .inversePrimary
                                      .withValues(alpha: .7),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'cairo',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              PlayButton(adhanData: adhans, index: index),
                            ],
                          ),
                          // leading: PlayButton(),
                        ),
                      ),
                    ),
                    isSelected
                        ? Expanded(
                            flex: 2,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Obx(
                                  () => SquarePercentIndicator(
                                    width: 45,
                                    height: 45,
                                    borderRadius: 4,
                                    shadowWidth: 1.5,
                                    progressWidth: 2,
                                    shadowColor: Colors.transparent,
                                    progressColor:
                                        index ==
                                            notificationCtrl
                                                .state
                                                .downloadIndex
                                                .value
                                        ? notificationCtrl
                                                  .state
                                                  .isDownloading
                                                  .value
                                              ? context
                                                    .theme
                                                    .colorScheme
                                                    .surface
                                              : Colors.transparent
                                        : Colors.transparent,
                                    progress:
                                        notificationCtrl.state.progress.value,
                                  ),
                                ),
                                isSelected
                                    ? Icon(
                                        Icons.done,
                                        size: 28,
                                        color:
                                            context.theme.colorScheme.surface,
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
      },
    );
  }
}
