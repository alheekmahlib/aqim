import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// صف إعدادات قابل للنقر مع مفتاح تبديل ومؤشر تحميل مدمج.
///
/// عند النقر يعرض المفتاح القيمة الجديدة فورًا (وضع متفائل) مع دائرة تحميل
/// بجوار المفتاح وتعتيم خفيف للصف حتى اكتمال [onChanged] — إن كان يعيد
/// Future يُنتظر اكتماله الفعلي، وإلا يكتمل فورًا فلا يظهر المؤشر.
class CustomSwitchWidget<T extends GetxController> extends StatefulWidget {
  final bool value;
  final Function(bool) onChanged;
  final T controller;
  final String title;
  final double? startPadding;
  final double? topPadding;
  final double? endPadding;
  final double? bottomPadding;
  final double? startMargin;
  final double? topMargin;
  final double? endMargin;
  final double? bottomMargin;
  final Widget? titleWidget;
  final Color? continerColor;
  const CustomSwitchWidget({
    super.key,
    required this.value,
    required this.onChanged,
    required this.controller,
    required this.title,
    this.startPadding = 0.0,
    this.topPadding = 0.0,
    this.endPadding = 0.0,
    this.bottomPadding = 0.0,
    this.startMargin = 0.0,
    this.topMargin = 1.0,
    this.endMargin = 0.0,
    this.bottomMargin = 1.0,
    this.titleWidget,
    this.continerColor,
  });

  @override
  State<CustomSwitchWidget<T>> createState() => _CustomSwitchWidgetState<T>();
}

class _CustomSwitchWidgetState<T extends GetxController>
    extends State<CustomSwitchWidget<T>> {
  bool _busy = false;
  bool? _optimisticValue;

  bool get _displayValue => _optimisticValue ?? widget.value;

  /// المسار الوحيد لكل مصادر النقر (نقر الصف/المفتاح/السحب):
  /// يعرض القيمة الجديدة فورًا ويحجب النقرات حتى اكتمال عمل onChanged.
  Future<void> _run(bool next) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _optimisticValue = next;
    });
    try {
      await Future.sync(() => widget.onChanged.call(next));
    } catch (e, st) {
      log(
        'Switch "${widget.title}" onChanged failed',
        name: 'CustomSwitch',
        error: e,
        stackTrace: st,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _optimisticValue = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        widget.startMargin ?? 0.0,
        widget.topMargin ?? 0.0,
        widget.endMargin ?? 0.0,
        widget.bottomMargin ?? 0.0,
      ),
      child: GestureDetector(
        onTap: () => _run(!_displayValue),
        child: Opacity(
          opacity: _busy ? 0.6 : 1.0,
          child: Container(
            padding: EdgeInsetsDirectional.fromSTEB(
              widget.startPadding ?? 0.0,
              widget.topPadding ?? 0.0,
              widget.endPadding ?? 0.0,
              widget.bottomPadding ?? 0.0,
            ),
            decoration: BoxDecoration(
              color:
                  widget.continerColor ??
                  Theme.of(context).colorScheme.surface.withValues(alpha: .3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child:
                        widget.titleWidget ??
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.title.tr,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.theme.colorScheme.inversePrimary
                                  .withValues(alpha: .7),
                            ),
                          ),
                        ),
                  ),
                ),
                // خانة سبينر بعرض متغير كي لا يقفز التخطيط عند ظهورها/اختفائها
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  width: _busy ? 24.0 : 0.0,
                  height: 18.0,
                  alignment: Alignment.center,
                  child: _busy
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: context.theme.colorScheme.surface,
                            strokeWidth: 2,
                          ),
                        )
                      : null,
                ),
                CustomSwitch(
                  value: _displayValue,
                  busy: _busy,
                  onChanged: _run,
                  activeColor: context.theme.colorScheme.secondaryContainer,
                  inactiveTrackColor: context
                      .theme
                      .colorScheme
                      .secondaryContainer
                      .withValues(alpha: .5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomSwitch extends StatelessWidget {
  final bool value;
  final bool busy;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveTrackColor;
  final Color? thumbColor;
  final double width;
  final double height;

  const CustomSwitch({
    super.key,
    required this.value,
    this.busy = false,
    required this.onChanged,
    this.activeColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.width = 61,
    this.height = 31,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final trackColor = value
        ? (activeColor ?? context.theme.primaryColorLight)
        : (inactiveTrackColor ?? context.theme.colorScheme.primaryContainer);
    const thumbPadding = 3.0;
    const thumbWidth = 40.0;
    final maxOffset = width - thumbWidth - (thumbPadding * 2);

    final thumbAtEnd = isRtl ? !value : value;

    return GestureDetector(
      onTap: () {
        if (busy) return;
        onChanged?.call(!value);
      },
      onHorizontalDragEnd: (details) {
        if (busy || details.primaryVelocity == null) return;
        final swipeRight = details.primaryVelocity! > 0;
        final swipeLeft = details.primaryVelocity! < 0;
        if (isRtl) {
          if (swipeLeft && !value) {
            onChanged?.call(true);
          } else if (swipeRight && value) {
            onChanged?.call(false);
          }
        } else {
          if (swipeRight && !value) {
            onChanged?.call(true);
          } else if (swipeLeft && value) {
            onChanged?.call(false);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: trackColor,
        ),
        padding: const EdgeInsets.all(thumbPadding),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: thumbAtEnd ? maxOffset : 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: thumbWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: value
                      ? (thumbColor ?? context.theme.colorScheme.surface)
                      : (thumbColor ?? context.theme.colorScheme.surface)
                            .withValues(alpha: .5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
