part of '../home.dart';

class HomeController extends GetxController {
  static HomeController get instance =>
      GetInstance().putOrFind(() => HomeController());
  int _currentIndex = 1; // البداية بصفحة الصلاة في الوسط
  final floatyMenuController = FloaticaMenuController();

  int get currentIndex => _currentIndex;

  void changeIndex(int index) {
    _currentIndex = index;
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().setVisible(
        index == NavBarTab.prayer.index,
      );
    }
    // if (isWeb) {
    //   final tab = NavBarTab.values[index];
    //   _updateWebUrl(tab.urlPath);
    // }
    update();
  }

  // void _updateWebUrl(String path) {
  //   try {
  //     // ignore: avoid_web_libraries_in_flutter
  //     // استخدام SystemNavigator لتحديث URL بدون إعادة تحميل
  //     WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  //     SystemNavigator.routeInformationUpdated(
  //       uri: Uri.parse(path),
  //       replace: true,
  //     );
  //   } catch (_) {}
  // }
}
