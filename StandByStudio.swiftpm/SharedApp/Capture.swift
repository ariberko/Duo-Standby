import SwiftUI

/// Helpers for App Store screenshots taken on the simulator.
/// With `-screenshotLandscape` full screen views are drawn sideways and without buttons,
/// so a portrait capture turns into a clean landscape image.
enum Capture {
    static let landscape = ProcessInfo.processInfo.arguments.contains("-screenshotLandscape")
}

private struct CaptureLandscape: ViewModifier {
    func body(content: Content) -> some View {
        if Capture.landscape {
            GeometryReader { geo in
                content
                    .ignoresSafeArea()
                    .frame(width: geo.size.height, height: geo.size.width)
                    .rotationEffect(.degrees(90))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .ignoresSafeArea()
            .background(Color.black)
        } else {
            content
        }
    }
}

extension View {
    func captureLandscape() -> some View { modifier(CaptureLandscape()) }
}
