import 'dart:developer';

import 'package:aqim/core/utils/constants/extensions/custom_error_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '/presentation/controllers/general/general_controller.dart';
import '../../core/services/location/locations.dart';
import '../splash/splash.dart';

class FlutterMapController extends GetxController {
  static FlutterMapController get instance =>
      GetInstance().putOrFind(() => FlutterMapController());

  // Observable variables
  final Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);
  final RxBool isLoadingLocation = false.obs;
  final RxString selectedAddress = ''.obs;
  final mapController = MapController();

  // Search variables
  final TextEditingController searchController = TextEditingController();
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearching = false.obs;
  final generalCtrl = GeneralController.instance;

  // Default location (Damascus)
  final LatLng defaultLocation = const LatLng(33.5138, 36.2765);

  double get currentZoom => mapController.camera.zoom;

  void get zoomIn =>
      mapController.move(mapController.camera.center, currentZoom + 1);

  void get zoomOut =>
      mapController.move(mapController.camera.center, currentZoom - 1);

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Handle map tap to select location
  void onMapTap(LatLng location) {
    selectedLocation.value = location;
    selectedAddress.value =
        'الموقع المحدد: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';

    // Move camera to selected location
    mapController.move(location, 15.0);

    log(
      'Location selected: ${location.latitude}, ${location.longitude}',
      name: 'FlutterMapController',
    );
  }

  /// Confirm selected location
  Future<void> confirmLocation() async {
    if (selectedLocation.value == null) {
      Get.context!.showCustomErrorSnackBar('pleaseSelectLocation'.tr);
      return;
    }

    isLoadingLocation.value = true;

    try {
      final location = selectedLocation.value!;

      // Set manual location
      await GeneralController.instance.initManualLocation(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      Get.back(); // Close map screen
      SplashScreenController.instance.state.customWidgetIndex.value = 2;

      log(
        'Location confirmed: (${location.latitude}, ${location.longitude})',
        name: 'FlutterMapController',
      );
    } catch (e) {
      log('Error confirming location: $e', name: 'FlutterMapController');
      Get.context!.showCustomErrorSnackBar('failedToSetLocation'.tr);
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<void> searchCities(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;
    try {
      final results = await HuaweiLocationHelper.instance.searchCities(query);
      searchResults.value = results;
    } catch (e) {
      Get.context!.showCustomErrorSnackBar('failedToSearchCities'.tr);
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> selectCity(Map<String, dynamic> city) async {
    try {
      await generalCtrl.initManualLocation(
        latitude: city['latitude'],
        longitude: city['longitude'],
      );

      Get.back(); // Close bottom sheet
      SplashScreenController.instance.state.customWidgetIndex.value = 2;

      Get.context!.showCustomErrorSnackBar(
        '${'locationSetSuccessfully'.tr}: ${city['name']}',
      );
    } catch (e) {
      Get.context!.showCustomErrorSnackBar('${'failedToSetLocation'.tr}: $e');
    }
  }
}
