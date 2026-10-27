import 'dart:io';

import 'package:aqim/core/utils/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

extension ShareAppExtension on void {
  Future<void> shareApp() async {
    final box = Get.context!.findRenderObject() as RenderBox?;
    final ByteData bytes = await rootBundle.load(
      'assets/images/aqim_banner.png',
    );
    final Uint8List list = bytes.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/aqim_banner.png').create();
    file.writeAsBytesSync(list);
    final params = ShareParams(
      text:
          'تطبيق "أَقِم - مكتبة الحكمة" هو رفيقك اليومي للحفاظ على صلاتك.\n\nللتحميل:\n${ApiConstants.downloadAppUrl}',
      files: [XFile(file.path)],
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );

    await SharePlus.instance.share(params);
  }
}
