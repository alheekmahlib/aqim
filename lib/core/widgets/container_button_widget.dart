import 'package:aqim/core/utils/constants/extensions/alignment_rotated_extension.dart';
import 'package:aqim/core/utils/constants/svg_constants.dart';
import 'package:aqim/core/utils/helpers/glass_tokens.dart';
import 'package:aqim/core/widgets/glass/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/utils.dart';

import '/core/utils/constants/extensions/svg_extensions.dart';

class ContainerButtonWidget extends StatelessWidget {
  final String? svgPath;
  final String? title;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final double? svgHeight;
  final Color? backgroundColor;
  final Color? shadowColor;
  final Color? svgColor;
  final Color? borderColor;
  final Widget? child;
  final IconData? icon;
  final double? verticalMargin;
  final double? horizontalMargin;
  final bool? withShape;
  final Color? titleColor;
  final double? borderRadius;
  final double? fontSize;
  final MainAxisAlignment? mainAxisAlignment;
  final Color? shapeColor;
  final bool? isLoading;
  final double? horizontalPadding;
  final double? verticalPadding;

  /// Whether to use gradient background or solid color
  /// If true: uses LinearGradient with backgroundColor and its transparent variant
  /// If false: uses solid backgroundColor
  final bool useGradient;

  /// Glass intensity in Liquid Glass mode (ignored in classic themes).
  final GlassVariant glassVariant;

  const ContainerButtonWidget({
    super.key,
    this.svgPath,
    this.onPressed,
    this.width,
    this.backgroundColor,
    this.shadowColor,
    this.svgColor,
    this.title,
    this.child,
    this.svgHeight,
    this.borderColor,
    this.icon,
    this.height,
    this.verticalMargin,
    this.horizontalMargin,
    this.useGradient = true,
    this.withShape = true,
    this.titleColor,
    this.borderRadius,
    this.fontSize,
    this.mainAxisAlignment,
    this.shapeColor,
    this.isLoading = false,
    this.horizontalPadding,
    this.verticalPadding,
    this.glassVariant = GlassVariant.subtle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: verticalMargin ?? 0.0,
        horizontal: horizontalMargin ?? 0.0,
      ),
      child: context.glassTokens == null
          ? _classicBuild(context)
          : _glassBuild(context),
    );
  }

  /// Liquid Glass variant: the decoration is replaced by a glass shape,
  /// content and size semantics stay identical.
  Widget _glassBuild(BuildContext context) {
    return GlassContainer(
      radius: borderRadius ?? 16.0,
      variant: glassVariant,
      onTap: onPressed,
      child: SizedBox(
        height: (height ?? 56),
        width: (width ?? double.infinity),
        child: contentStack(context, withShapes: false),
      ),
    );
  }

  Widget _classicBuild(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 16.0),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius ?? 16.0),
        splashColor: Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          height: (height ?? 56),
          width: (width ?? double.infinity),
          decoration: BoxDecoration(
            gradient: useGradient
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor ?? Theme.of(context).colorScheme.surface,
                      (backgroundColor ?? Theme.of(context).colorScheme.surface)
                          .withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: useGradient
                ? null
                : backgroundColor ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(borderRadius ?? 16.0),
            border: Border.all(
              color: borderColor ?? Theme.of(context).highlightColor,
              width: 1.5,
            ),
          ),
          child: contentStack(context, withShapes: withShape!),
        ),
      ),
    );
  }

  Widget contentStack(BuildContext context, {required bool withShapes}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background decorative element
        if (withShapes) ...[
          alignmentLayout(
            Positioned(
              right: -20,
              top: -10,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      shapeColor ??
                      context.theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
            Positioned(
              left: -20,
              top: -10,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      shapeColor ??
                      context.theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
        // Main content
        title != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment:
                      mainAxisAlignment ?? MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (icon != null || svgPath != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            borderRadius ?? 16,
                          ),
                        ),
                        child: icon != null
                            ? Icon(
                                icon!,
                                size: svgHeight ?? 24,
                                color: svgColor ?? Colors.white,
                              )
                            : customSvgWithColor(
                                svgPath ?? SvgPath.svgAlert,
                                height: svgHeight ?? 24,
                                color: svgColor ?? Colors.white,
                              ),
                      ),
                      const Gap(12),
                    ],
                    Flexible(
                      child: isLoading!
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: context.theme.colorScheme.surface,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              title!,
                              style: TextStyle(
                                fontSize: (fontSize ?? 16),
                                color: titleColor ?? Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'cairo',
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding ?? 8.0,
                  vertical: verticalPadding ?? 8.0,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
      ],
    );
  }
}
