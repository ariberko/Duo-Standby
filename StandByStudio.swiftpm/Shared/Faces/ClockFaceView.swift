import SwiftUI

/// The foreground of a clock widget. The background is drawn by `ClockBackground`.
struct ClockFaceView: View {
    let style: ClockStyle
    let date: Date
    let settings: StudioSettings

    var body: some View {
        switch style {
        case .flip: FlipFace(date: date, settings: settings)
        case .minimal: MinimalFace(date: date, settings: settings)
        case .analog: AnalogFace(date: date, settings: settings)
        case .bold: BoldFace(date: date, settings: settings)
        case .neon: NeonFace(date: date, settings: settings)
        case .lcd: LCDFace(date: date, settings: settings)
        case .terminal: TerminalFace(date: date, settings: settings)
        case .synthwave: SynthwaveFace(date: date, settings: settings)
        case .galaxy: GalaxyFace(date: date, settings: settings)
        case .aurora: AuroraFace(date: date, settings: settings)
        case .nebula: NebulaFace(date: date, settings: settings)
        case .orbit: OrbitFace(date: date, settings: settings)
        case .words: WordsFace(date: date, settings: settings)
        case .binary: BinaryFace(date: date, settings: settings)
        case .studio: StudioFace(date: date, settings: settings)
        }
    }
}

struct ClockBackground: View {
    let style: ClockStyle
    let settings: StudioSettings

    var body: some View {
        switch style {
        case .flip, .minimal:
            Color.black
        case .analog:
            LinearGradient(colors: [Color(white: 0.16), Color(white: 0.04)], startPoint: .top, endPoint: .bottom)
        case .bold:
            Color(white: 0.05)
        case .neon:
            Color(red: 0.06, green: 0.02, blue: 0.12)
        case .lcd:
            LinearGradient(colors: [Color(white: 0.34), Color(white: 0.2)], startPoint: .top, endPoint: .bottom)
        case .terminal:
            ZStack {
                Color.black
                Scanlines().fill(Color.green.opacity(0.07))
            }
        case .synthwave:
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.02, blue: 0.25), Color(red: 0.45, green: 0.05, blue: 0.45), Color(red: 0.95, green: 0.3, blue: 0.5)],
                startPoint: .top, endPoint: .bottom
            )
        case .galaxy:
            ZStack {
                RadialGradient(colors: [Color(red: 0.32, green: 0.1, blue: 0.5), .black], center: .center, startRadius: 4, endRadius: 140)
                Starfield(count: 60, seed: 3)
            }
        case .aurora:
            ZStack {
                Color(red: 0.01, green: 0.03, blue: 0.08)
                Ellipse().fill(Color(red: 0.1, green: 0.95, blue: 0.55).opacity(0.75))
                    .frame(width: 190, height: 56).rotationEffect(.degrees(-18)).offset(x: -10, y: -42).blur(radius: 22)
                Ellipse().fill(Color(red: 0.55, green: 0.3, blue: 1).opacity(0.6))
                    .frame(width: 170, height: 50).rotationEffect(.degrees(12)).offset(x: 30, y: -8).blur(radius: 24)
                Ellipse().fill(Color(red: 0.1, green: 0.7, blue: 0.9).opacity(0.45))
                    .frame(width: 150, height: 40).rotationEffect(.degrees(-8)).offset(x: -30, y: 20).blur(radius: 20)
                Starfield(count: 25, seed: 9)
            }
        case .nebula:
            ZStack {
                Color.black
                RadialGradient(colors: [Color(red: 1, green: 0.4, blue: 0.3).opacity(0.85), .clear], center: .topLeading, startRadius: 0, endRadius: 130)
                RadialGradient(colors: [Color(red: 0.3, green: 0.3, blue: 1).opacity(0.85), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 140)
                RadialGradient(colors: [Color(red: 0.9, green: 0.2, blue: 0.8).opacity(0.5), .clear], center: .center, startRadius: 0, endRadius: 80)
                Starfield(count: 40, seed: 21)
            }
        case .orbit:
            ZStack {
                Color(red: 0.02, green: 0.02, blue: 0.06)
                Starfield(count: 30, seed: 5)
            }
        case .words:
            Color(white: 0.07)
        case .binary:
            Color(red: 0.03, green: 0.05, blue: 0.1)
        case .studio:
            LinearGradient(colors: [settings.accent.opacity(0.45), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
