import SwiftUI

struct StyleDetailView: View {
    let style: ClockStyle

    @EnvironmentObject private var store: Store
    @EnvironmentObject private var model: SettingsModel
    @State private var showingPreview = false
    @State private var showingStore = false

    private var isLocked: Bool { !store.isUnlocked(style.pack) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TimelineView(.everyMinute) { context in
                    ClockTile(style: style, date: context.date, settings: model.settings)
                }
                .frame(maxWidth: 320)
                .overlay(alignment: .topTrailing) {
                    if isLocked { LockBadge() }
                }

                PackBadge(pack: style.pack)

                Button {
                    showingPreview = true
                } label: {
                    Label("Try it in StandBy view", systemImage: "rectangle.landscape.rotate")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if isLocked {
                    Button {
                        showingStore = true
                    } label: {
                        Label("Unlock \(style.pack.title)", systemImage: "lock.open")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                HowToCard()
            }
            .padding()
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(style.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingPreview) {
            StandByPreviewView(style: style)
        }
        .sheet(isPresented: $showingStore) {
            NavigationStack { StoreView() }
        }
    }
}

/// A full-screen mock of StandBy: two widgets side by side on black.
struct StandByPreviewView: View {
    let style: ClockStyle

    @EnvironmentObject private var model: SettingsModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { geo in
                TimelineView(.everyMinute) { context in
                    if geo.size.width > geo.size.height {
                        HStack(spacing: 20) { tiles(date: context.date) }
                    } else {
                        VStack(spacing: 20) { tiles(date: context.date) }
                    }
                }
                .padding(24)
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .captureLandscape()
        .overlay(alignment: .bottom) {
            if !Capture.landscape {
                Text("Tap anywhere to close")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 12)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }

    @ViewBuilder
    private func tiles(date: Date) -> some View {
        ClockTile(style: style, date: date, settings: model.settings)
            .frame(maxWidth: 360, maxHeight: 360)
        StudioWidgetTile(widget: .calendar, date: date, settings: model.settings, photo: model.photo)
            .frame(maxWidth: 360, maxHeight: 360)
    }
}
