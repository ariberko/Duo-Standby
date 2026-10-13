import SwiftUI

/// Draws widget content at real small-widget size, then scales it to fit.
struct WidgetTile<Content: View, Background: View>: View {
    var padding: CGFloat = 12
    @ViewBuilder var content: Content
    @ViewBuilder var background: Background

    private static let side: CGFloat = 158

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width, geo.size.height) / Self.side
            ZStack {
                background
                content.padding(padding)
            }
            .frame(width: Self.side, height: Self.side)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .scaleEffect(scale)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct ClockTile: View {
    let style: ClockStyle
    let date: Date
    let settings: StudioSettings

    var body: some View {
        WidgetTile {
            ClockFaceView(style: style, date: date, settings: settings)
        } background: {
            ClockBackground(style: style, settings: settings)
        }
    }
}

struct StudioWidgetTile: View {
    let widget: StudioWidget
    let date: Date
    let settings: StudioSettings
    let photo: UIImage?

    var body: some View {
        WidgetTile(padding: widget.contentPadding) {
            content
        } background: {
            StudioWidgetBackground(widget: widget, settings: settings)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch widget {
        case .calendar:
            CalendarFace(date: date, settings: settings)
        case .battery:
            BatteryFace(
                level: UIDevice.current.batteryLevel,
                isCharging: UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full,
                settings: settings
            )
        case .moon:
            MoonFace(date: date).padding(2)
        case .countdown:
            CountdownFace(now: date, settings: settings)
        case .quote:
            QuoteFace(text: QuoteBook.quote(for: date), settings: settings)
        case .photo:
            PhotoFace(image: photo, date: date, settings: settings)
        }
    }
}

struct LockBadge: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(7)
            .background(Color.black.opacity(0.6), in: Circle())
            .padding(8)
    }
}

struct PackBadge: View {
    let pack: Pack

    var body: some View {
        Label(pack.title, systemImage: pack.symbol)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(pack == .free ? Color.green.opacity(0.25) : Color.orange.opacity(0.25), in: Capsule())
    }
}
