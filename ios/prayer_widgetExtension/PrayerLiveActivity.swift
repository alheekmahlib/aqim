import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct PrayerCountdownAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var nextName: String
        var nextAt: Date
        var nextTimeText: String
        var prevName: String
        var prevAt: Date
        var nextLabel: String?
        var refreshLabel: String?
    }

    var nextLabel: String
    var elapsedLabel: String
}

private func countdownRange(to target: Date) -> ClosedRange<Date> {
    let now = Date()
    return now...max(now, target)
}

private func elapsedRange(since start: Date, until end: Date) -> ClosedRange<Date> {
    let now = Date()
    let from = min(now, start)
    return from...max(from, end)
}

// The app language may differ from the device language. Use the translated
// label's first strong script to keep Arabic, Kurdish and Urdu layouts RTL.
private func direction(for text: String) -> LayoutDirection {
    for scalar in text.unicodeScalars {
        switch scalar.value {
        case 0x0590...0x08FF, 0xFB1D...0xFDFF, 0xFE70...0xFEFF:
            return .rightToLeft
        default:
            if CharacterSet.letters.contains(scalar) { return .leftToRight }
        }
    }
    return .leftToRight
}

private extension Color {
    static let aqimDeepTeal = Color(red: 0.01, green: 0.10, blue: 0.13)
    static let aqimMint = Color(red: 0.69, green: 0.84, blue: 0.72)
    static let aqimWhite = Color(red: 0.94, green: 0.97, blue: 0.96)
}

private struct PrayerMark: View {
    var body: some View {
        Image(systemName: "moon.stars.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.aqimMint)
            .accessibilityHidden(true)
    }
}

private struct CountdownTimer: View {
    let target: Date
    var size: CGFloat = 28

    var body: some View {
        Text(timerInterval: countdownRange(to: target), countsDown: true)
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .environment(\.layoutDirection, .leftToRight)
    }
}

@available(iOS 17.0, *)
struct PrayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerCountdownAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(.aqimDeepTeal)
                .activitySystemActionForegroundColor(.aqimWhite)
                .environment(\.layoutDirection, direction(for: context.state.nextLabel ?? context.attributes.nextLabel))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.state.nextLabel ?? context.attributes.nextLabel)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.aqimWhite.opacity(0.75))
                            .lineLimit(1)
                        Text(context.state.nextName)
                            .font(.headline)
                            .foregroundStyle(Color.aqimWhite)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .environment(\.layoutDirection, direction(for: context.state.nextLabel ?? context.attributes.nextLabel))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(context.state.nextTimeText)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.aqimWhite.opacity(0.8))
                            .lineLimit(1)
                        CountdownTimer(target: context.state.nextAt, size: 17)
                            .foregroundStyle(Color.aqimMint)
                            .frame(width: 76, alignment: .trailing)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color.aqimMint)
                            .accessibilityHidden(true)
                        Text(context.attributes.elapsedLabel)
                        Text(context.state.prevName).fontWeight(.semibold)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(timerInterval: elapsedRange(since: context.state.prevAt, until: context.state.nextAt), countsDown: false)
                            .monospacedDigit()
                            .lineLimit(1)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.aqimWhite.opacity(0.85))
                    .padding(.top, 5)
                    .environment(\.layoutDirection, direction(for: context.state.nextLabel ?? context.attributes.nextLabel))
                }
            } compactLeading: {
                PrayerMark()
            } compactTrailing: {
                CountdownTimer(target: context.state.nextAt, size: 12)
                    .foregroundStyle(Color.aqimMint)
                    .frame(width: 58, alignment: .center)
            } minimal: {
                PrayerMark()
            }
        }
    }

    private func lockScreenView(context: ActivityViewContext<PrayerCountdownAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.aqimMint.opacity(0.14))
                    PrayerMark()
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 3) {
                    Text(context.state.nextLabel ?? context.attributes.nextLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.aqimWhite.opacity(0.76))
                        .lineLimit(1)
                    Text(context.state.nextName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.aqimWhite)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(context.state.nextTimeText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.aqimWhite.opacity(0.84))
                        .lineLimit(1)
                    CountdownTimer(target: context.state.nextAt, size: 25)
                        .foregroundStyle(Color.aqimMint)
                        .frame(width: 110, alignment: .trailing)
                }
            }

            Rectangle()
                .fill(Color.aqimWhite.opacity(0.14))
                .frame(height: 1)
                .accessibilityHidden(true)

            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.aqimMint)
                    .accessibilityHidden(true)
                Text(context.attributes.elapsedLabel)
                    .foregroundStyle(Color.aqimWhite.opacity(0.76))
                    .lineLimit(1)
                    .layoutPriority(1)
                Text(context.state.prevName)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.aqimWhite)
                    .lineLimit(1)
                    .layoutPriority(1)
                Text(timerInterval: elapsedRange(since: context.state.prevAt, until: context.state.nextAt), countsDown: false)
                    .monospacedDigit()
                    .foregroundStyle(Color.aqimWhite.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 68)
                    .environment(\.layoutDirection, .leftToRight)
                Spacer(minLength: 0)
                Button(intent: RefreshPrayerCountdownIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.aqimMint)
                        .frame(width: 44, height: 44)
                        .background(Color.aqimMint.opacity(0.12), in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(context.state.refreshLabel ?? "Refresh"))
            }
            .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
