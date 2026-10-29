import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/widgets/container_button_widget.dart';
import '../../domain/local_adhan_audio.dart';
import '../custom_adhan_controller.dart';

/// قسم المؤذنين المخصصين داخل ورقة أصوات الأذان: يظهر عند تفعيل ميزة
/// «استخدام مؤذن مخصص»، ويعرض الاستيراد والمعاينة والاختيار وإعادة
/// التسمية والحذف بالنمط البصري نفسه.
class CustomAdhanSection extends StatelessWidget {
  const CustomAdhanSection({super.key, required this.controller});

  final CustomAdhanController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'customAdhanSectionTitle'.tr,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ),
        if (controller.errorKey.value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              controller.errorKey.value.tr,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        for (final audio in controller.audios)
          _CustomAdhanTile(controller: controller, audio: audio),
        if (controller.audios.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'customAdhanEmpty'.tr,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.inversePrimary.withValues(alpha: .7),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ContainerButtonWidget(
            key: const ValueKey('custom-adhan-import'),
            title: controller.importing.value
                ? 'customAdhanImporting'.tr
                : 'customAdhanImport'.tr,
            titleColor: Theme.of(context).colorScheme.inversePrimary,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: .3),
            width: Get.width,
            withShape: false,
            useGradient: false,
            borderRadius: 8,
            mainAxisAlignment: MainAxisAlignment.start,
            onPressed: controller.importing.value
                ? () {}
                : controller.importAudio,
          ),
        ),
      ],
    ),
  );
}

class _CustomAdhanTile extends StatelessWidget {
  const _CustomAdhanTile({required this.controller, required this.audio});

  final CustomAdhanController controller;
  final LocalAdhanAudio audio;

  String get _durationLabel {
    final minutes = audio.duration.inMinutes;
    final seconds = audio.duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.activeAudioId == audio.id;
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        border: Border.all(
          color: isSelected
              ? context.theme.colorScheme.surface
              : context.theme.colorScheme.surface.withValues(alpha: .5),
          width: isSelected ? 2 : 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: context.theme.colorScheme.surface.withValues(
          alpha: isSelected ? .5 : .2,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          minTileHeight: 40,
          onTap: () => controller.select(audio),
          title: Text(
            audio.name,
            style: TextStyle(
              color: context.theme.colorScheme.inversePrimary.withValues(
                alpha: .7,
              ),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'cairo',
            ),
          ),
          subtitle: Text(
            _durationLabel,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 11,
              color: context.theme.colorScheme.inversePrimary.withValues(
                alpha: .6,
              ),
            ),
          ),
          leading: IconButton(
            key: ValueKey('preview-${audio.id}'),
            icon: Obx(
              () => Icon(
                controller.previewingId.value == audio.id
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
                color: context.theme.colorScheme.inversePrimary,
              ),
            ),
            onPressed: () => controller.preview(audio),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: ValueKey('rename-${audio.id}'),
                tooltip: 'customAdhanRename'.tr,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: context.theme.colorScheme.inversePrimary,
                ),
                onPressed: () => _rename(context, audio),
              ),
              IconButton(
                key: ValueKey('delete-${audio.id}'),
                tooltip: 'customAdhanDelete'.tr,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: context.theme.colorScheme.error,
                ),
                onPressed: () => _confirmDelete(context, audio),
              ),
              if (isSelected)
                Icon(
                  Icons.done,
                  size: 24,
                  color: context.theme.colorScheme.surface,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, LocalAdhanAudio audio) async {
    final nameController = TextEditingController(text: audio.name);
    final name = await Get.dialog<String>(
      Dialog(
        backgroundColor: context.theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'customAdhanRename'.tr,
                style: const TextStyle(fontFamily: 'cairo', fontSize: 16),
              ),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(hintText: 'customAdhanNameHint'.tr),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
                  TextButton(
                    onPressed: () => Get.back(result: nameController.text),
                    child: Text('customAdhanSave'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await controller.rename(audio.id, name);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LocalAdhanAudio audio,
  ) async {
    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: context.theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'customAdhanDeleteConfirm'.trParams({'name': audio.name}),
                style: const TextStyle(fontFamily: 'cairo', fontSize: 15),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: Text('delete'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await controller.delete(audio.id);
    }
  }
}
