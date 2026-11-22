part of '../../prayers.dart';

// ---------------------------------------------------------------------------
// Design 3 — ستوري عمودي 9:16
// ---------------------------------------------------------------------------

class _StoryShareCard extends StatelessWidget {
  final ShareCardData data;

  const _StoryShareCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: data.gradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 0.75,
                  colors: [
                    Colors.white.withValues(alpha: .14),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 34, 26, 30),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data.weekday,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'cairo',
                        color: Colors.white.withValues(alpha: .85),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        _HijriCrescent(
                          month: data.hijriMonth,
                          color: Colors.white,
                          height: 50,
                          alpha: .15,
                        ),
                        Text(
                          data.hijriDate,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'cairo',
                            color: Colors.white.withValues(alpha: .85),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.prayerName,
                  style: const TextStyle(
                    fontSize: 30,
                    fontFamily: 'cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const Gap(4),
                Text(
                  data.nextPrayerLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'cairo',
                    color: Colors.white.withValues(alpha: .7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(22),
                SizedBox(
                  width: 236,
                  height: 236,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(236, 236),
                        painter: _ProgressRingPainter(progress: data.progress),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                data.prayerTime,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontFamily: 'cairo',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                '${data.timeLeftTitle} ${data.timeLeftValue}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'cairo',
                                  color: Colors.white.withValues(alpha: .8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .18),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 190),
                        child: Text(
                          data.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'cairo',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _ShareLogo(color: Colors.white, height: 22),
                    Text(
                      data.appName,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'cairo',
                        color: Colors.white.withValues(alpha: .75),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  const _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .16);
    canvas.drawCircle(center, radius, track);

    final p = progress.clamp(0.0, 1.0);
    if (p > 0) {
      final active = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: -pi / 2 + 2 * pi,
          colors: [Colors.white.withValues(alpha: .55), Colors.white],
        ).createShader(rect);
      canvas.drawArc(rect, -pi / 2, 2 * pi * p, false, active);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
