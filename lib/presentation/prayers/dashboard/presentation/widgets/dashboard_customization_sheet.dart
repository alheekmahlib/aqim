part of '../../../prayers.dart';

class DashboardCustomizationSheet extends StatelessWidget {
  const DashboardCustomizationSheet({super.key, required this.controller});
  final DashboardLayoutController controller;

  @override
  Widget build(BuildContext context) {
    final previewData = DashboardPreviewData.localized();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .65,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'dashboardCustomizeHint'.tr,
              textAlign: TextAlign.center,
              style: dashboardText(context, 13),
            ),
          ),
          Expanded(
            child: Obx(
              () => ReorderableListView.builder(
                key: const ValueKey('dashboard-reorder-list'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                buildDefaultDragHandles: false,
                onReorderItem: controller.reorder,
                itemCount: controller.layout.value.panels.length,
                itemBuilder: (context, index) {
                  final preference = controller.layout.value.panels[index];
                  final definition = dashboardRegistry[preference.panel]!;
                  return Material(
                    key: ValueKey(preference.panel.id),
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: Semantics(
                              label: 'dashboardDrag'.trParams({
                                'name': definition.title,
                              }),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                          ),
                          DashboardPanelPreview(
                            key: ValueKey('preview-${preference.panel.id}'),
                            child: definition.previewBuilder(previewData),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Semantics(
                              label: definition.title,
                              toggled: preference.visible,
                              excludeSemantics: true,
                              onTap: () => controller.toggle(
                                preference.panel,
                                !preference.visible,
                              ),
                              child:
                                  CustomSwitchWidget<DashboardLayoutController>(
                                    controller: controller,
                                    title: definition.title,
                                    titleWidget: Text(
                                      definition.title,
                                      style: dashboardText(context, 14),
                                    ),
                                    continerColor: Colors.transparent,
                                    value: preference.visible,
                                    onChanged: (value) => controller.toggle(
                                      preference.panel,
                                      value,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Obx(
            () => controller.saveFailed.value
                ? TextButton(
                    onPressed: controller.retrySave,
                    child: Text('dashboardSaveRetry'.tr),
                  )
                : const SizedBox.shrink(),
          ),
          TextButton.icon(
            onPressed: controller.reset,
            icon: const Icon(Icons.restore),
            label: Text('dashboardRestore'.tr),
          ),
        ],
      ),
    );
  }
}
