part of '../prayers.dart';

/// شريط اختيار تصميم بطاقة المشاركة.
///
/// Design selection strip shown inside the share sheet.
class ShareDesignPicker extends StatelessWidget {
  final ShareCardDesign selected;
  final ValueChanged<ShareCardDesign> onSelected;

  const ShareDesignPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final design in ShareCardDesign.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ShareDesignChip(
                design: design,
                selected: design == selected,
                onTap: () => onSelected(design),
              ),
            ),
          ),
      ],
    );
  }
}

/// زر اختيار تصميم واحد.
///
/// A single design option button.
class ShareDesignChip extends StatelessWidget {
  final ShareCardDesign design;
  final bool selected;
  final VoidCallback onTap;

  const ShareDesignChip({
    super.key,
    required this.design,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.theme.colorScheme.inversePrimary;
    final foreground = selected ? accent : accent.withValues(alpha: .65);
    return Material(
      color: selected ? accent.withValues(alpha: .12) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: .7)
                  : accent.withValues(alpha: .22),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(design.icon, size: 20, color: foreground),
              const Gap(6),
              Text(
                design.labelKey.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'cairo',
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: foreground,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
