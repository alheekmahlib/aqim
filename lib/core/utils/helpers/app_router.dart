import 'package:get/get.dart';

import '../../../presentation/about_app/about_app.dart';
import '../../../presentation/feedback/screens/feedback_conversation_screen.dart';
import '../../../presentation/feedback/screens/feedback_thread_screen.dart';
import '../../../presentation/home/home.dart';
import '../../../presentation/ourApp/screen/our_apps_screen.dart';
import '../../../presentation/prayers/prayers.dart';
import '../../../presentation/qibla/qibla.dart';
import '../../../presentation/teaching_prayer/teaching.dart';

class AppRouter {
  static const String homeScreen = '/homeScreen';
  static const String prayerScreen = '/prayerScreen';
  static const String qiblaScreen = '/qiblaScreen';
  static const String ourApps = '/ourApps';
  static const String aboutApp = '/aboutApp';
  static const String teachingPrayer = '/teachingPrayer';
  static const String feedback = '/feedback';
  static const String feedbackConversation = '/feedbackConversation';

  static List<GetPage> pages = [
    GetPage(
      name: homeScreen,
      binding: PrayerDashboardBinding(),
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: prayerScreen,
      binding: PrayerDashboardBinding(),
      page: () => PrayerScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: qiblaScreen,
      page: () => QiblaScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: ourApps,
      page: () => const OurApps(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: aboutApp,
      page: () => const AboutApp(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: teachingPrayer,
      page: () => const TeachingPrayerScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: feedback,
      page: () => const FeedbackThreadScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: feedbackConversation,
      page: () => const FeedbackConversationScreen(),
      transition: Transition.fadeIn,
    ),
  ];

  // static Map<String, WidgetBuilder> get routes => {
  //       prayerScreen: (context) => PrayerScreen(),
  //     };

  // // إضافة المسارات إلى التطبيق باستخدام GetMaterialApp
  // static Widget buildApp() {
  //   return GetMaterialApp(
  //     initialRoute: prayerScreen,
  //     getPages: [
  //       GetPage(
  //         name: prayerScreen,
  //         page: () => PrayerScreen(),
  //       ),
  //     ],
  //   );
  // }
}
