import ActivityKit
import AppIntents
import Foundation

/// Runs in the app process; boundary snapshots are saved when Flutter syncs.
@available(iOS 17.0, *)
struct RefreshPrayerCountdownIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Refresh prayer countdown"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let now = Date().timeIntervalSince1970 * 1000
        let entries = UserDefaults.standard.array(forKey: "prayerCountdownBoundaries") as? [[String: Any]] ?? []
        guard let entry = entries.last(where: {
            (($0["at"] as? NSNumber)?.doubleValue ?? .infinity) <= now
        }), let nextAt = (entry["nextAt"] as? NSNumber)?.doubleValue,
              nextAt > now,
              let previousAt = (entry["prevAt"] as? NSNumber)?.doubleValue else {
            return .result()
        }
        for activity in Activity<PrayerCountdownAttributes>.activities {
            let state = PrayerCountdownAttributes.ContentState(
                nextName: entry["nextName"] as? String ?? "",
                nextAt: Date(timeIntervalSince1970: nextAt / 1000),
                nextTimeText: entry["nextTime"] as? String ?? "",
                prevName: entry["prevName"] as? String ?? "",
                prevAt: Date(timeIntervalSince1970: previousAt / 1000),
                nextLabel: entry["nextLabel"] as? String,
                refreshLabel: activity.content.state.refreshLabel
            )
            await activity.update(ActivityContent(state: state, staleDate: state.nextAt))
        }
        return .result()
    }
}
