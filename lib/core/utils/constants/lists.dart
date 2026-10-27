import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/core/utils/constants/svg_constants.dart';
import '../../../presentation/controllers/theme_controller.dart';
import '../../../presentation/prayers/prayers.dart';
// import '../../../presentation/screens/calendar/events.dart';
// import '../../../presentation/screens/prayers/prayers.dart';
// import '../../../presentation/screens/qibla/qibla.dart';
import '../helpers/app_router.dart';

final List screensList = [
  {
    'name': 'home',
    'svgUrl': 'assets/svg/logo/zad_muslim_white.svg',
    'imagePath': 'assets/images/home.png',
    'route': () => Get.toNamed(AppRouter.homeScreen),
    'width': 240.0,
  },
  {
    'name': 'prayer',
    'svgUrl': 'assets/svg/prayer_logo.svg',
    'imagePath': 'assets/images/prayer.png',
    'route': () => Get.toNamed(AppRouter.prayerScreen),
    'width': 240.0,
  },
  {
    'name': 'qibla',
    'svgUrl': 'assets/svg/qebla_logo.svg',
    'imagePath': 'assets/images/qibla.jpeg',
    'route': () => Get.toNamed(AppRouter.qiblaScreen),
    'width': 70.0,
  },
  // {
  //   'name': 'calender',
  //   'svgUrl': 'assets/svg/azkar.svg',
  //   'imagePath': 'assets/images/calender.png',
  //   'route': () => Get.toNamed(AppRouter.calendarScreen),
  //   'width': 240.0
  // },
];

const List themeList = [
  {
    'name': AppTheme.blue,
    'title': 'oldMode',
    'svgUrl': 'assets/svg/theme/theme1.svg',
  },
  {
    'name': AppTheme.dark,
    'title': 'darkMode',
    'svgUrl': 'assets/svg/theme/theme2.svg',
  },
  {
    'name': AppTheme.liquidGlass,
    'title': 'liquidGlassMode',
    'svgUrl': 'assets/svg/theme/theme3.svg',
  },
];

const List<Map<String, dynamic>> prayerHadithsList = [
  {
    'fromQuran': '',
    'ayahNumber': '',
    'fromSunnah':
        'سُئِلَ رَسولُ اللهِ صَلَّى اللَّهُ عليه وسلَّمَ عن وَقْتِ الصَّلَوَاتِ، فَقالَ وَقْتُ صَلَاةِ الفَجْرِ ما لَمْ يَطْلُعْ قَرْنُ الشَّمْسِ الأوَّلُ',
    'rule':
        'الراوي : عبدالله بن عمرو | المحدث : مسلم | المصدر : صحيح مسلم | الصفحة أو الرقم : 612',
  },
  {
    'fromQuran': '',
    'ayahNumber': '',
    'fromSunnah':
        'كان رسولُ اللهِ صلَّى اللهُ عليه وسلَّم إذا صلَّى الفجرَ جلَس في مُصلَّاه حتَّى تطلُعَ الشَّمسُ وكانوا يجلِسونَ فيتحدَّثونَ ويأخُذونَ في أمرِ الجاهليَّةِ فيضحَكونَ ويتبسَّمُ صلَّى اللهُ عليه وسلَّم ',
    'rule':
        'الراوي : جابر بن سمرة | المحدث : ابن حبان | المصدر : صحيح ابن حبان | الصفحة أو الرقم : 6259',
  },
  {
    'fromQuran':
        'قول الله تعالى: {أَقِمِ الصَّلَاةَ لِدُلُوكِ الشَّمْسِ إِلَى غَسَقِ اللَّيْلِ}',
    'ayahNumber': '[الإسراء: 78]',
    'fromSunnah':
        'كانَ رَسولُ اللَّهِ صَلَّى اللهُ عليه وسلَّمَ يُصَلِّي المَكْتُوبَةَ؟ قَالَ: كانَ يُصَلِّي الهَجِيرَ - وهي الَّتي تَدْعُونَهَا الأُولَى - حِينَ تَدْحَضُ الشَّمْسُ...',
    'rule':
        'الراوي : أبو برزة الأسلمي نضلة بن عبيد | المحدث : البخاري | المصدر : صحيح البخاري | الصفحة أو الرقم : 599',
  },
  {
    'fromQuran': '',
    'ayahNumber': '',
    'fromSunnah':
        'أنَّ رَسولَ اللهِ صَلَّى اللَّهُ عليه وسلَّمَ كانَ يُصَلِّي العَصْرَ وَالشَّمْسُ مُرْتَفِعَةٌ حَيَّةٌ، فَيَذْهَبُ الذَّاهِبُ إلى العَوَالِي، فَيَأْتي العَوَالِي وَالشَّمْسُ مُرْتَفِعَةٌ.',
    'rule':
        'الراوي : أنس بن مالك | المحدث : مسلم | المصدر : صحيح مسلم | الصفحة أو الرقم : 621',
  },
  {
    'fromQuran': '',
    'ayahNumber': '',
    'fromSunnah':
        'عَنْ سَلَمَةَ بنِ الأكْوَعِ: أنَّ رَسولَ اللهِ صَلَّى اللَّهُ عليه وسلَّمَ كانَ يُصَلِّي المَغْرِبَ إذَا غَرَبَتِ الشَّمْسُ، وَتَوَارَتْ بالحِجَابِ.',
    'rule':
        'الراوي : سلمة بن الأكوع | المحدث : مسلم | المصدر : صحيح مسلم | الصفحة أو الرقم : 636',
  },
  {
    'fromQuran': '',
    'ayahNumber': '',
    'fromSunnah':
        '...ووَقْتُ صَلاةِ العِشاءِ إلى نِصْفِ اللَّيْلِ الأوْسَطِ...',
    'rule':
        'الراوي : عبدالله بن عمرو | المحدث : مسلم | المصدر : صحيح مسلم | الصفحة أو الرقم : 612',
  },
  {
    'fromQuran': '',
    'ayahNumber': '',
    'fromSunnah':
        'أَخَّرَ النبيُّ صَلَّى اللهُ عليه وسلَّمَ صَلَاةَ العِشَاءِ إلى نِصْفِ اللَّيْلِ، ثُمَّ صَلَّى، ثُمَّ قَالَ: قدْ صَلَّى النَّاسُ ونَامُوا، أما إنَّكُمْ في صَلَاةٍ ما انْتَظَرْتُمُوهَا، وزَادَ ابنُ أبِي مَرْيَمَ، أخْبَرَنَا يَحْيَى بنُ أيُّوبَ، حدَّثَني حُمَيْدٌ، سَمِعَ أنَسَ بنَ مَالِكٍ، قَالَ: كَأَنِّي أنْظُرُ إلى وبِيصِ خَاتَمِهِ لَيْلَتَئِذٍ.',
    'rule':
        'الراوي : أنس بن مالك | المحدث : البخاري | المصدر : صحيح البخاري | الصفحة أو الرقم : 572',
  },
  {
    'fromQuran': '',
    'ayahNumber': '',
    'fromSunnah':
        'يَنْزِلُ رَبُّنا تَبارَكَ وتَعالَى كُلَّ لَيْلةٍ إلى السَّماءِ الدُّنْيا حِينَ يَبْقَى ثُلُثُ اللَّيْلِ الآخِرُ، يقولُ: مَن يَدْعُونِي، فأسْتَجِيبَ له؟ مَن يَسْأَلُنِي فأُعْطِيَهُ؟ مَن يَستَغْفِرُني فأغْفِرَ له؟',
    'rule':
        'الراوي : أبو هريرة | المحدث : البخاري | المصدر : صحيح البخاري | الصفحة أو الرقم : 1145 | التخريج : أخرجه البخاري (1145)، ومسلم (758)',
  },
];

List<Map<String, dynamic>> notificationOptions = [
  {'title': 'nothing', 'icon': Icons.cancel_outlined},
  {'title': 'silent', 'icon': Icons.music_off_outlined},
  {'title': 'bell', 'icon': Icons.notifications_active},
  {'title': 'sound', 'icon': Icons.volume_up_rounded},
];

List<Map<String, dynamic>> prohibitionTimesList = [
  {
    'title': 'من الفجر إلى أن ترتفع الشمس قيد رمح.',
    'hadith':
        'شَهِدَ عِندِي رِجَالٌ مَرْضِيُّونَ وأَرْضَاهُمْ عِندِي عُمَرُ، أنَّ النبيَّ صَلَّى اللهُ عليه وسلَّمَ نَهَى عَنِ الصَّلَاةِ بَعْدَ الصُّبْحِ حتَّى تَشْرُقَ الشَّمْسُ، وبَعْدَ العَصْرِ حتَّى تَغْرُبَ.',
    'source':
        'الراوي : عمر بن الخطاب | المحدث : البخاري | المصدر : صحيح البخاري | الصفحة أو الرقم : 581',
  },
  {
    'title': 'حين يقوم قائم الظهيرة إلى أن تزول.',
    'hadith':
        'إِذَا طَلَعَ حَاجِبُ الشَّمْسِ فأخِّرُوا الصَّلَاةَ حتَّى تَرْتَفِعَ، وإذَا غَابَ حَاجِبُ الشَّمْسِ فأخِّرُوا الصَّلَاةَ حتَّى تَغِيبَ.',
    'source':
        'الراوي : عبدالله بن عمر | المحدث : البخاري | المصدر : صحيح البخاري | الصفحة أو الرقم : 583',
  },
  {
    'title': 'من صلاة العصر حتى يتم غروب الشمس.',
    'hadith':
        'ثَلَاثُ سَاعَاتٍ كانَ رَسولُ اللهِ صَلَّى اللَّهُ عليه وَسَلَّمَ يَنْهَانَا أَنْ نُصَلِّيَ فِيهِنَّ، أَوْ أَنْ نَقْبُرَ فِيهِنَّ مَوْتَانَا: حِينَ تَطْلُعُ الشَّمْسُ بَازِغَةً حتَّى تَرْتَفِعَ، وَحِينَ يَقُومُ قَائِمُ الظَّهِيرَةِ حتَّى تَمِيلَ الشَّمْسُ، وَحِينَ تَضَيَّفُ الشَّمْسُ لِلْغُرُوبِ حتَّى تَغْرُبَ.',
    'source':
        'الراوي : عقبة بن عامر | المحدث : مسلم | المصدر : صحيح مسلم | الصفحة أو الرقم : 831',
  },
];

List<Map<String, dynamic>> qiblaList = [
  {
    'qibla': SvgPath.svgQiblaQibla,
    'height': 350.0,
    'arrow': '',
    'kaaba': SvgPath.svgHomeKaaba,
    'arrowHeight': 350.0,
  },
];

final prayerList = [
  'Fajr',
  'Sunrise',
  AdhanController.instance.getFridayDhuhrName,
  'Asr',
  AdhanController.instance.getMaghribName,
  'Isha',
  'middleOfTheNight',
  'lastThirdOfTheNight',
];

final prayerListList = [
  'Fajr'.tr,
  'Sunrise'.tr,
  AdhanController.instance.getFridayDhuhrName.tr,
  'Asr'.tr,
  AdhanController.instance.getMaghribName.tr,
  'Isha'.tr,
  'middleOfTheNight'.tr,
  'lastThirdOfTheNight'.tr,
];

final prayerColorList = [
  const Color(0xff232323),
  const Color(0xffbababa),
  const Color(0xff0098EE),
  const Color(0xffB8E0EA),
  const Color(0xffF17148),
  const Color(0xff0a0f29),
  const Color(0xff0a0f29),
  const Color(0xff0a0f29),
];

const List<String> weekDaysFullName = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
