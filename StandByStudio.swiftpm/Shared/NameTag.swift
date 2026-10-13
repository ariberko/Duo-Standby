import SwiftUI

enum NameTagStyle: String, Codable, CaseIterable, Identifiable {
    case classic, hello, alert, neon, minimal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "Classic"
        case .hello: "Hello"
        case .alert: "Alert"
        case .neon: "Neon"
        case .minimal: "Minimal"
        }
    }
}

/// Big text for tent mode: a name and title, or a sign like "Do Not Disturb".
struct NameTag: Codable, Equatable {
    var title = "Your Name"
    var subtitle = "Your Title"
    var style: NameTagStyle = .classic

    struct Preset: Identifiable {
        let id: String
        let symbol: String
        let title: String
        let subtitle: String
        let style: NameTagStyle
    }

    static let presets: [Preset] = [
        Preset(id: "Name & Title", symbol: "person.text.rectangle", title: "Your Name", subtitle: "Your Title", style: .classic),
        Preset(id: "Hello", symbol: "hand.wave", title: "Your Name", subtitle: "", style: .hello),
        Preset(id: "Do Not Disturb", symbol: "moon.fill", title: "Do Not Disturb", subtitle: "In a meeting", style: .alert),
        Preset(id: "On a Call", symbol: "phone.fill", title: "On a Call", subtitle: "Please wait", style: .alert),
        Preset(id: "Back Soon", symbol: "clock", title: "Back in 5", subtitle: "Grabbing coffee", style: .minimal),
        Preset(id: "Welcome", symbol: "sparkles", title: "Welcome!", subtitle: "Come on in", style: .neon),
        Preset(id: "Busy", symbol: "xmark.circle.fill", title: "Busy", subtitle: "Talk later", style: .alert),
        Preset(id: "Lunch Break", symbol: "fork.knife", title: "Lunch Break", subtitle: "Back at 1:00", style: .classic),
        Preset(id: "Focus", symbol: "brain.head.profile", title: "Focus Time", subtitle: "Deep work in progress", style: .minimal),
        Preset(id: "Recording", symbol: "record.circle", title: "Recording", subtitle: "Quiet please", style: .alert),
        Preset(id: "Available", symbol: "checkmark.circle.fill", title: "Available", subtitle: "Come say hi", style: .neon),
        Preset(id: "Be Right Back", symbol: "figure.walk", title: "Be Right Back", subtitle: "", style: .minimal),
        Preset(id: "Quiet Please", symbol: "speaker.slash.fill", title: "Quiet Please", subtitle: "Someone is sleeping", style: .minimal),
        Preset(id: "Out of Office", symbol: "airplane", title: "Out of Office", subtitle: "Back next week", style: .classic),
        Preset(id: "Gaming", symbol: "gamecontroller.fill", title: "Gaming", subtitle: "Do not pause me", style: .neon),
        Preset(id: "Birthday", symbol: "birthday.cake", title: "Happy Birthday!", subtitle: "", style: .hello),
    ]

    mutating func apply(_ preset: Preset) {
        title = preset.title
        subtitle = preset.subtitle
        style = preset.style
    }

    private static let key = "nameTag"

    static func load() -> NameTag {
        guard let data = AppGroup.defaults.data(forKey: key),
              let tag = try? JSONDecoder().decode(NameTag.self, from: data)
        else { return NameTag() }
        return tag
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppGroup.defaults.set(data, forKey: Self.key)
    }
}

/// Fills whatever space it gets. Text sizes follow the height, then shrink to fit the width.
struct NameTagView: View {
    let tag: NameTag
    let accent: Color
    var fontDesign: Font.Design = .rounded

    private static let helloRed = Color(red: 0.86, green: 0.1, blue: 0.15)

    var body: some View {
        GeometryReader { geo in
            content(height: geo.size.height)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder
    private func content(height h: CGFloat) -> some View {
        switch tag.style {
        case .classic:
            ZStack {
                Color.white
                lines(height: h, titleColor: .black, subtitleColor: accent, design: fontDesign, weight: .bold)
                    .padding(.horizontal, h * 0.1)
                    .padding(.top, h * 0.06)
            }
            .overlay(alignment: .top) {
                accent.frame(height: h * 0.08)
            }

        case .hello:
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text("HELLO")
                        .font(.system(size: h * 0.16, weight: .black, design: .rounded))
                    Text("my name is")
                        .font(.system(size: h * 0.07, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .padding(.vertical, h * 0.03)
                ZStack {
                    Color.white
                    lines(height: h * 0.75, titleColor: .black, subtitleColor: .gray, design: .serif, weight: .semibold, italic: true)
                        .padding(.horizontal, h * 0.08)
                }
                Self.helloRed.frame(height: h * 0.06)
            }
            .background(Self.helloRed)

        case .alert:
            ZStack {
                Color(red: 0.82, green: 0.08, blue: 0.12)
                lines(height: h, titleColor: .white, subtitleColor: .white.opacity(0.85), design: fontDesign, weight: .heavy)
                    .padding(.horizontal, h * 0.1)
            }

        case .neon:
            ZStack {
                Color(red: 0.05, green: 0.02, blue: 0.1)
                lines(height: h, titleColor: .white, subtitleColor: accent, design: .rounded, weight: .semibold)
                    .shadow(color: accent, radius: h * 0.02)
                    .shadow(color: accent, radius: h * 0.06)
                    .padding(.horizontal, h * 0.1)
            }

        case .minimal:
            ZStack {
                Color.black
                lines(height: h, titleColor: .white, subtitleColor: .white.opacity(0.55), design: fontDesign, weight: .light)
                    .padding(.horizontal, h * 0.1)
            }
        }
    }

    private func lines(
        height h: CGFloat,
        titleColor: Color,
        subtitleColor: Color,
        design: Font.Design,
        weight: Font.Weight,
        italic: Bool = false
    ) -> some View {
        VStack(spacing: h * 0.02) {
            Text(verbatim: tag.title.isEmpty ? " " : tag.title)
                .font(.system(size: h * (tag.subtitle.isEmpty ? 0.4 : 0.32), weight: weight, design: design))
                .italic(italic)
                .foregroundStyle(titleColor)
            if !tag.subtitle.isEmpty {
                Text(verbatim: tag.subtitle)
                    .font(.system(size: h * 0.13, weight: .medium, design: design))
                    .foregroundStyle(subtitleColor)
            }
        }
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.1)
        .lineLimit(1)
    }
}

/// A name tag the user saved as their own preset.
struct SavedNameTag: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var tag: NameTag
}

enum SavedNameTags {
    private static let key = "savedNameTags"

    static func load() -> [SavedNameTag] {
        guard let data = AppGroup.defaults.data(forKey: key),
              let items = try? JSONDecoder().decode([SavedNameTag].self, from: data)
        else { return [] }
        return items
    }

    static func save(_ items: [SavedNameTag]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        AppGroup.defaults.set(data, forKey: key)
    }
}
