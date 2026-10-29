part of '../qibla.dart';

class QiblaCompassWidget extends StatelessWidget {
  QiblaCompassWidget({super.key});

  final qiblaCtrl = QiblaController.instance;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<QiblaController>(
      builder: (qiblaCtrl) {
        // السماح بعرض البوصلة إن كان اتجاه القبلة معروفًا (من الموقع المخزن)
        // حتى لو كانت خدمة/صلاحية الموقع قيد التحديث.
        final bool hasQibla = qiblaCtrl.qiblaDirection.value != 0.0;
        if (!hasQibla &&
            (!qiblaCtrl.locationEnabled.value ||
                !qiblaCtrl.permissionGranted.value)) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        return StreamBuilder<CompassXEvent>(
          stream: CompassX.events,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            } else if (snapshot.hasError) {
              return const Center(child: CircularProgressIndicator.adaptive());
            } else if (!snapshot.hasData ||
                qiblaCtrl.qiblaDirection.value == 0.0) {
              return const Center(child: CircularProgressIndicator.adaptive());
            } else {
              double direction = snapshot.data!.heading;
              final qiblaIndex = qiblaCtrl.qiblaWidgetIndex.value;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                qiblaCtrl.direction.value = direction;
                final bool nextIsCorrect = qiblaCtrl
                    .isDirectionCorrect(direction)
                    .value;
                // Trigger haptic only on transition into correct alignment.
                if (nextIsCorrect && !qiblaCtrl.isCorrect.value) {
                  HapticFeedback.mediumImpact();
                }
                qiblaCtrl.qiblaColor.value = Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: nextIsCorrect ? .4 : .2);
                qiblaCtrl.isCorrect.value = nextIsCorrect;
              });
              final theme = context.theme.colorScheme;
              final double targetAngleDeg = _normalizeAngle(
                qiblaCtrl.qiblaDirection.value - direction,
              );
              final bool aligned = qiblaCtrl.isCorrect.value;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: context.customOrientation(
                  Stack(
                    children: [
                      // Header card with Kaaba watermark and Qibla degrees
                      HeaderCardWidget(aligned: aligned),

                      // Compass area
                      compassBuild(
                        qiblaIndex,
                        qiblaCtrl,
                        theme,
                        targetAngleDeg,
                        aligned,
                        direction,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Header card with Kaaba watermark and Qibla degrees
                      Expanded(child: HeaderCardWidget(aligned: aligned)),

                      // Compass area
                      Expanded(
                        child: compassBuild(
                          qiblaIndex,
                          qiblaCtrl,
                          theme,
                          targetAngleDeg,
                          aligned,
                          direction,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Center compassBuild(
    int qiblaIndex,
    QiblaController qiblaCtrl,
    ColorScheme theme,
    double targetAngleDeg,
    bool aligned,
    double direction,
  ) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double size = (constraints.biggest.shortestSide * 0.9)
              .clamp(220.0, 420.0)
              .toDouble();
          final double dialSize = size;
          final double needleSize = (qiblaList[qiblaIndex]['height'] + 20)
              .toDouble();

          return RepaintBoundary(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dial painter (ticks + NESW)
                  SizedBox(
                    width: dialSize,
                    height: dialSize,
                    child: Transform.rotate(
                      angle:
                          (-qiblaCtrl.qiblaDirection.value *
                          (3.141592653589793 / 180)),
                      child: CustomPaint(
                        painter: _CompassDialPainter(
                          ringColor: theme.primary.withValues(alpha: .15),
                          tickColor: theme.inversePrimary.withValues(
                            alpha: .55,
                          ),
                          textColor: theme.inversePrimary.withValues(alpha: .7),
                        ),
                      ),
                    ),
                  ),

                  // Rotating needle (SVG from assets)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: targetAngleDeg),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      final double angleRad = value * (3.141592653589793 / 180);
                      return Transform.rotate(
                        angle: angleRad,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: aligned ? 1.06 : 1.0,
                          curve: Curves.easeOut,
                          child: child,
                        ),
                      );
                    },
                    child: customSvg(
                      qiblaList[qiblaIndex]['qibla'],
                      height: needleSize,
                    ),
                  ),

                  // Current heading badge at bottom
                  Positioned(
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.surface.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.outline.withValues(alpha: .18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.explore_rounded,
                            size: 18,
                            color: theme.inversePrimary.withValues(alpha: .7),
                          ),
                          const Gap(6),
                          Text(
                            '${direction.toStringAsFixed(1)}°',
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.inversePrimary.withValues(
                                alpha: .75,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Normalize angle to [-180, 180] for shortest rotation animation.
double _normalizeAngle(double angle) {
  while (angle > 180) {
    angle -= 360;
  }
  while (angle < -180) {
    angle += 360;
  }
  return angle;
}
