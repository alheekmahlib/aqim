part of '../../prayers.dart';

class SettingPrayerTimes extends StatelessWidget {
  final int? listNum;
  final bool isOnePrayer;
  final bool showGeneralOptions;
  const SettingPrayerTimes({
    super.key,
    this.listNum,
    this.showGeneralOptions = true,
    required this.isOnePrayer,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdhanController>(
      id: 'init_athan',
      init: Get.find<AdhanController>(),
      builder: (adhanCtrl) => Column(
        children: [
          Text(
            'SetPrayerTimes'.tr,
            style: TextStyle(
              color: context.theme.colorScheme.inversePrimary.withValues(
                alpha: .7,
              ),
              fontFamily: 'cairo',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Gap(4),
          ListView.builder(
            primary: false,
            shrinkWrap: true,
            itemCount: isOnePrayer ? 1 : adhanCtrl.prayerNameList.length,
            itemBuilder: (context, i) {
              int index;
              if (listNum != null) {
                index = listNum!;
              } else {
                index = i;
              }
              final bool hasIqama = IqamaOffsets.hasIqama(index);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isOnePrayer
                        ? const SizedBox.shrink()
                        : Text(
                            '${adhanCtrl.prayerNameList[index]['title']!}'.tr,
                            style: TextStyle(
                              color: context.theme.colorScheme.inversePrimary
                                  .withValues(alpha: .7),
                              fontFamily: 'cairo',
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.surface.withValues(
                          alpha: .3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              '${adhanCtrl.prayerNameList[index]['time']!}'
                                  .convertNumbersToCurrentLang(),
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.theme.colorScheme.inversePrimary
                                    .withValues(alpha: .7),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              0,
                              0,
                              16,
                              0,
                            ),
                            child: Row(
                              children: [
                                ReactiveNumberText(
                                  text:
                                      '${adhanCtrl.state.adjustments.getAdjustmentByIndex(index)}'
                                          .convertNumbers(
                                            Get.locale!.languageCode,
                                          ),
                                  style: TextStyle(
                                    fontFamily: 'cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: context
                                        .theme
                                        .colorScheme
                                        .inversePrimary
                                        .withValues(alpha: .7),
                                  ),
                                ),
                                const Gap(8),
                                Container(
                                  height: 25,
                                  width: 75,
                                  decoration: BoxDecoration(
                                    color: context.theme.colorScheme.surface,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: 25,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            await adhanCtrl.adjustPrayerTime(
                                              index,
                                            );
                                          },
                                          style: ButtonStyle(
                                            padding: WidgetStateProperty.all(
                                              EdgeInsets.zero,
                                            ),
                                            elevation: WidgetStateProperty.all(
                                              0,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            size: 16,
                                            color: context.theme.canvasColor,
                                          ),
                                        ),
                                      ),
                                      context.vDivider(
                                        height: 20,
                                        color: context.theme.canvasColor,
                                      ),
                                      SizedBox(
                                        width: 25,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            await adhanCtrl.adjustPrayerTime(
                                              index,
                                              isAdding: false,
                                            );
                                          },
                                          style: ButtonStyle(
                                            padding: WidgetStateProperty.all(
                                              EdgeInsets.zero,
                                            ),
                                            elevation: WidgetStateProperty.all(
                                              0,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 16,
                                            color: context.theme.canvasColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasIqama) _IqamaAdjustRow(prayerIndex: index),
                  ],
                ),
              );
            },
          ),
          if (!isOnePrayer && showGeneralOptions) ...[
            const Gap(8),
            CustomSwitchWidget<AdhanController>(
              controller: adhanCtrl,
              title: 'iqamaNotifications',
              value: adhanCtrl.state.iqamaNotificationsEnabled.value,
              startPadding: 16.0,
              endPadding: 16.0,
              onChanged: (bool value) =>
                  adhanCtrl.toggleIqamaNotifications(value),
            ),
            CustomSwitchWidget<AdhanController>(
              controller: adhanCtrl,
              title: 'showIqamaTimes',
              value: adhanCtrl.state.showIqamaTimes.value,
              startPadding: 16.0,
              endPadding: 16.0,
              onChanged: (bool value) => adhanCtrl.toggleShowIqamaTimes(value),
            ),
            CustomSwitchWidget<AdhanController>(
              controller: adhanCtrl,
              title: 'prayerCountdownNotification',
              value: adhanCtrl.state.prayerCountdownEnabled.value,
              startPadding: 16.0,
              endPadding: 16.0,
              onChanged: (bool value) =>
                  adhanCtrl.togglePrayerCountdownNotification(value),
            ),
          ],
        ],
      ),
    );
  }
}
