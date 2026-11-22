part of '../../prayers.dart';

// ---------------------------------------------------------------------------
// Design 1 — كلاسيكي (التصميم الأصلي)
// ---------------------------------------------------------------------------

class _ClassicShareCard extends StatelessWidget {
  final ShareCardData data;

  const _ClassicShareCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: data.gradient),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withValues(alpha: .15),
              border: Border.all(
                color: Colors.white.withValues(alpha: .1),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                _HijriCrescent(month: data.hijriMonth),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Gap(6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.nextPrayerLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'cairo',
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: .9),
                                height: 1.0,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              data.prayerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontFamily: 'cairo',
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data.prayerTime,
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'cairo',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    ShareProgressBar(progress: data.progress),
                    Center(
                      child: Text(
                        '${data.timeLeftTitle} ${data.timeLeftValue}',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'cairo',
                          color: Colors.white.withValues(alpha: .8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.hijriDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'cairo',
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.place_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            data.location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'cairo',
                              color: Colors.white.withValues(alpha: .9),
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    const _ShareLogo(color: Colors.white, height: 20),
                  ],
                ),
              ],
            ),
          ),
          const Gap(3),
          Text(
            data.appName,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'cairo',
              color: Colors.white.withValues(alpha: .7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(5),
        ],
      ),
    );
  }
}
