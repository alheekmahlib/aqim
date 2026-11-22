part of '../../prayers.dart';

// ---------------------------------------------------------------------------
// Design 2 — جدول اليوم
// ---------------------------------------------------------------------------

class _TimetableShareCard extends StatelessWidget {
  final ShareCardData data;

  const _TimetableShareCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final slots = data.prayers.take(5).toList();
    return Container(
      decoration: BoxDecoration(gradient: data.gradient),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.prayerTimesTitle,
                      style: const TextStyle(
                        fontSize: 19,
                        fontFamily: 'cairo',
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      '${data.weekday} • ${data.hijriDate}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'cairo',
                        color: Colors.white.withValues(alpha: .7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.schedule_rounded,
                  size: 22,
                  color: Colors.white.withValues(alpha: .8),
                ),
              ],
            ),
            const Gap(14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final slot in slots)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _PrayerSlotTile(slot: slot),
                    ),
                  ),
              ],
            ),
            const Gap(14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .10),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: 15,
                    color: Colors.white.withValues(alpha: .85),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'cairo',
                        color: Colors.white.withValues(alpha: .9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${data.timeLeftTitle} ${data.timeLeftValue}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'cairo',
                      color: Colors.white.withValues(alpha: .75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _ShareLogo(color: Colors.white, height: 18),
                Text(
                  data.appName,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'cairo',
                    color: Colors.white.withValues(alpha: .7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerSlotTile extends StatelessWidget {
  final SharePrayerSlot slot;

  const _PrayerSlotTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    final active = slot.isNext;
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? Colors.white : Colors.white.withValues(alpha: .12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            slot.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'cairo',
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: active
                  ? _Palette.ink
                  : Colors.white.withValues(alpha: .75),
            ),
          ),
          const Gap(4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              slot.time,
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'cairo',
                fontWeight: FontWeight.w800,
                height: 1.3,
                color: active ? _Palette.ink : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
