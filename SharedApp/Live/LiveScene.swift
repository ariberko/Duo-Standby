import SwiftUI

enum LiveKeys {
    static let dvdText = "live.dvdText"
    static let ledText = "live.ledText"
    static let ledColor = "live.ledColor"
    static let timerMinutes = "live.timerMinutes"
    static let servingNumber = "live.servingNumber"
}

struct LiveSceneView: View {
    let scene: LiveScene
    var start: Date = .now
    /// Thumbnails pass true: frozen frame, no controls.
    var isThumbnail = false

    var body: some View {
        switch scene {
        case .dvd: DVDBounceScene(start: start, paused: isThumbnail)
        case .matrix: MatrixRainScene(start: start, paused: isThumbnail)
        case .starfield: StarfieldScene(start: start, paused: isThumbnail)
        case .mystify: MystifyScene(start: start, paused: isThumbnail)
        case .ledScroller: LEDScrollerScene(start: start, paused: isThumbnail)
        case .talkTimer: TalkTimerScene(showsControls: !isThumbnail)
        case .nowServing: NowServingScene(showsControls: !isThumbnail)
        case .fireplace: FireplaceScene(start: start, paused: isThumbnail)
        case .candle: CandleScene(start: start, paused: isThumbnail)
        case .lavaLamp: LavaLampScene(start: start, paused: isThumbnail)
        }
    }
}

/// Moves back and forth between 0 and `length`, like a ball between two walls.
func bounce(_ distance: Double, length: Double) -> (position: Double, bounces: Int) {
    guard length > 0 else { return (0, 0) }
    let n = Int(floor(distance / length))
    let rest = distance - Double(n) * length
    return (n % 2 == 0 ? rest : length - rest, n)
}

/// Full screen player. Keeps the screen awake.
struct LiveSceneHost: View {
    let scene: LiveScene

    @Environment(\.dismiss) private var dismiss
    @State private var start = Date.now

    var body: some View {
        LiveSceneView(scene: scene, start: start)
            .captureLandscape()
            .overlay(alignment: .topTrailing) {
                if !Capture.landscape {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(12)
                            .background(Color.black.opacity(0.4), in: Circle())
                    }
                    .padding()
                }
            }
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            .statusBarHidden()
            .persistentSystemOverlays(.hidden)
            .preferredColorScheme(.dark)
    }
}

struct LiveGalleryView: View {
    var isUnlocked: (Pack) -> Bool = { _ in true }
    var onLocked: (Pack) -> Void = { _ in }
    /// Set from outside (for example a tap on the Live widget) to start a scene right away.
    var requestedScene: Binding<LiveScene?> = .constant(nil)

    @State private var playing: LiveScene?
    @State private var thumbnailStart = Date.now.addingTimeInterval(-6)
    @AppStorage(LiveKeys.dvdText) private var dvdText = "DVD"
    @AppStorage(LiveKeys.ledText) private var ledText = "WELCOME"
    @AppStorage(LiveKeys.ledColor) private var ledColorHex = "#FF3B30"

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Full screen scenes for StandBy, tent mode or a desk. Tap one to play. The screen stays on.\n\nTip: add the Live widget to StandBy or your Home Screen. Tapping it opens the scene full screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(LiveScene.Group.allCases) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.title).font(.title3.bold())
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(LiveScene.allCases.filter { $0.group == group }) { scene in
                                card(scene)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Settings").font(.title3.bold())
                    LabeledContent("DVD text") {
                        TextField("DVD", text: $dvdText)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Scroller text") {
                        TextField("WELCOME", text: $ledText)
                            .multilineTextAlignment(.trailing)
                    }
                    ColorPicker("Scroller color", selection: Binding(
                        get: { Color(hex: ledColorHex) },
                        set: { ledColorHex = $0.hexString }
                    ), supportsOpacity: false)
                }
                .padding()
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding()
        }
        .navigationTitle("Live")
        .fullScreenCover(item: $playing) { scene in
            LiveSceneHost(scene: scene)
        }
        .onAppear { play(requestedScene.wrappedValue) }
        .onChange(of: requestedScene.wrappedValue) { _, scene in play(scene) }
    }

    private func play(_ scene: LiveScene?) {
        guard let scene else { return }
        requestedScene.wrappedValue = nil
        if isUnlocked(scene.pack) {
            playing = scene
        } else {
            onLocked(scene.pack)
        }
    }

    private func card(_ scene: LiveScene) -> some View {
        let locked = !isUnlocked(scene.pack)
        return Button {
            if locked { onLocked(scene.pack) } else { playing = scene }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                LiveSceneView(scene: scene, start: thumbnailStart, isThumbnail: true)
                    .frame(height: 110)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .allowsHitTesting(false)
                    .overlay(alignment: .topTrailing) {
                        if locked { LockBadge() }
                    }
                    .overlay(alignment: .bottomLeading) {
                        Image(systemName: "play.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5), in: Circle())
                            .padding(8)
                    }
                Text(scene.title).font(.subheadline.weight(.semibold))
                Text(scene.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
            }
        }
        .buttonStyle(.plain)
    }
}
