part of '../../prayers.dart';

class DashboardCustomizationSheet extends StatefulWidget {
  const DashboardCustomizationSheet({super.key, required this.controller});
  final DashboardLayoutController controller;

  @override
  State<DashboardCustomizationSheet> createState() =>
      _DashboardCustomizationSheetState();
}

class _DashboardCustomizationSheetState
    extends State<DashboardCustomizationSheet> {
  final _scrollController = ScrollController();
  final _gridKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
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
              () => ReorderableBuilder(
                scrollController: _scrollController,
                onReorderPositions: (positions) {
                  for (final position in positions) {
                    controller.reorder(position.oldIndex, position.newIndex);
                  }
                },
                builder: (children) => GridView(
                  key: _gridKey,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  children: children,
                ),
                children: [
                  for (final preference in controller.layout.value.panels)
                    Builder(
                      key: ValueKey(preference.panel.id),
                      builder: (context) {
                        final definition = dashboardRegistry[preference.panel]!;
                        return Material(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary
                                    .withValues(alpha: .2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Semantics(
                                  label: 'dashboardDrag'.trParams({
                                    'name': definition.title,
                                  }),
                                  child: Icon(
                                    Icons.drag_handle,
                                    size: 24,
                                    color: context
                                        .theme
                                        .colorScheme
                                        .inversePrimary,
                                  ),
                                ),
                                DashboardPanelPreview(
                                  key: ValueKey(
                                    'preview-${preference.panel.id}',
                                  ),
                                  child: definition.previewBuilder(previewData),
                                ),
                                Semantics(
                                  label: definition.title,
                                  toggled: preference.visible,
                                  excludeSemantics: true,
                                  onTap: () => controller.toggle(
                                    preference.panel,
                                    !preference.visible,
                                  ),
                                  child:
                                      CustomSwitchWidget<
                                        DashboardLayoutController
                                      >(
                                        controller: controller,
                                        title: definition.title,
                                        continerColor: Colors.transparent,
                                        value: preference.visible,
                                        onChanged: (value) => controller.toggle(
                                          preference.panel,
                                          value,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CustomButton(
              onPressed: controller.reset,
              width: Get.width * .7,
              icon: Icons.restore,
              borderRadius: 12,
              horizontalPadding: 16.0,
              backgroundColor: context.theme.colorScheme.surface.withValues(
                alpha: .1,
              ),
              iconWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restore,
                    color: context.theme.colorScheme.inversePrimary,
                  ),
                  const Gap(8),
                  Text(
                    'dashboardRestore'.tr,
                    style: dashboardText(context, 16).copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.theme.colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
