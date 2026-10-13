import SwiftUI
import WidgetKit

@main
struct StandByWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ClockWidget()
        NameTagWidget()
        CalendarWidget()
        BatteryWidget()
        MoonWidget()
        CountdownWidget()
        QuoteWidget()
        PhotoWidget()
    }
}

extension WidgetConfiguration {
    /// Settings every StandBy Studio widget shares.
    func standByStyle() -> some WidgetConfiguration {
        self
            .supportedFamilies([.systemSmall])
            .contentMarginsDisabled()
            .containerBackgroundRemovable(false)
    }
}

/// Blurs paid content and sends the tap to the in-app store.
struct LockedModifier: ViewModifier {
    let isLocked: Bool
    let pack: Pack

    @ViewBuilder
    func body(content: Content) -> some View {
        if isLocked {
            content
                .blur(radius: 8)
                .overlay {
                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text(pack.title)
                            .font(.system(size: 12, weight: .bold))
                        Text("Tap to unlock")
                            .font(.system(size: 10))
                            .opacity(0.8)
                    }
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .widgetURL(URL(string: "standbystudio://store"))
        } else {
            content
        }
    }
}

extension View {
    func locked(_ isLocked: Bool, pack: Pack) -> some View {
        modifier(LockedModifier(isLocked: isLocked, pack: pack))
    }
}
