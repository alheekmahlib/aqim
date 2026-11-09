import 'package:get/get.dart';

import '../../../../core/utils/constants/shared_preferences_constants.dart';
import '../../../ramadan/events.dart';
import '../general_controller.dart';

extension GeneralGetters on GeneralController {
  /// -------- [Getters] ----------

  List get eidDaysList => [
    '1-10',
    '2-10',
    '3-10',
    '10-12',
    '11-12',
    '12-12',
    '13-12',
  ];

  String get eidGreetingContent =>
      EventController.instance.hijriNow.hMonth == 10
      ? 'eidGreetingContent'.tr
      : 'eidGreetingContent2'.tr;

  bool get eidDays {
    String todayString =
        '${EventController.instance.hijriNow.hDay}-${EventController.instance.hijriNow.hMonth}';
    return eidDaysList.contains(todayString);
  }

  bool get isActiveLocation => state.box.read(IS_LOCATION_ACTIVE) ?? false;
  bool get isFirstLaunch => state.box.read(FIRST_LAUNCH) ?? false;
}
