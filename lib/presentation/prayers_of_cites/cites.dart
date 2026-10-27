import 'dart:developer' show log;

import 'package:adhan/adhan.dart';
import 'package:aqim/core/widgets/custom_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rounded_progress_bar/flutter_rounded_progress_bar.dart';
import 'package:flutter_rounded_progress_bar/rounded_progress_bar_style.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:timezone/timezone.dart' as tz;

import '/core/utils/helpers/date_formatter.dart';
import '../../core/services/location/locations.dart';
import '../../core/utils/constants/extensions/bottom_sheet_extension.dart';
import '../../core/utils/constants/extensions/extensions.dart';
import '../../core/utils/constants/extensions/svg_extensions.dart';
import '../../core/utils/constants/shared_preferences_constants.dart';
import '../../core/utils/constants/svg_constants.dart';
import '../../core/widgets/app_bar_widget.dart';
import '../../core/widgets/container_button_widget.dart';
import '../prayers/prayers.dart';
import '../splash/splash.dart';

part 'controller/prayers_of_cites_controller.dart';
part 'data/local/saved_cities_storage.dart';
part 'data/model/saved_city.dart';
part 'screens/city_prayer_times_screen.dart';
part 'screens/prayers_of_cites.dart';
part 'services/city_prayer_times_service.dart';
