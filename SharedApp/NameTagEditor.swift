import SwiftUI

/// Edit the name tag and show it full screen for tent mode.
struct NameTagEditorView: View {
    let accent: Color
    var fontDesign: Font.Design = .rounded
    var onSave: () -> Void = {}

    @State private var tag = NameTag.load()
    @State private var showingSign = false

    var body: some View {
        Form {
            Section {
                NameTagView(tag: tag, accent: accent, fontDesign: fontDesign)
                    .aspectRatio(2, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                Button {
                    showingSign = true
                } label: {
                    Label("Show full screen", systemImage: "rectangle.landscape.rotate")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowBackground(Color.clear)
            } footer: {
                Text("Fold your phone like a tent or stand it up. Tap the sign to show the buttons.")
            }

            Section("Quick start") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(NameTag.presets) { preset in
                            Button {
                                tag.apply(preset)
                            } label: {
                                Label(preset.id, systemImage: preset.symbol)
                                    .font(.subheadline)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Text") {
                TextField("Name or message", text: $tag.title)
                TextField("Second line (optional)", text: $tag.subtitle)
            }

            Section("Style") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                    ForEach(NameTagStyle.allCases) { style in
                        Button {
                            tag.style = style
                        } label: {
                            VStack(spacing: 6) {
                                NameTagView(tag: NameTag(title: tag.title, subtitle: tag.subtitle, style: style), accent: accent, fontDesign: fontDesign)
                                    .aspectRatio(2, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(tag.style == style ? accent : .clear, lineWidth: 3)
                                    }
                                Text(style.title).font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Name Tag")
        .onChange(of: tag) { _, newValue in
            newValue.save()
            onSave()
        }
        .fullScreenCover(isPresented: $showingSign) {
            TentSignView(tag: tag, accent: accent, fontDesign: fontDesign)
        }
    }
}

/// The sign itself, edge to edge. Keeps the screen awake while it shows.
struct TentSignView: View {
    let tag: NameTag
    let accent: Color
    var fontDesign: Font.Design = .rounded

    @Environment(\.dismiss) private var dismiss
    @State private var upsideDown = false
    @State private var showsControls = true

    var body: some View {
        NameTagView(tag: tag, accent: accent, fontDesign: fontDesign)
            .rotationEffect(.degrees(upsideDown ? 180 : 0))
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                if showsControls {
                    HStack(spacing: 12) {
                        Button {
                            upsideDown.toggle()
                        } label: {
                            Label("Flip", systemImage: "arrow.up.arrow.down")
                        }
                        Button {
                            dismiss()
                        } label: {
                            Label("Close", systemImage: "xmark")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black.opacity(0.6))
                    .padding(.bottom, 24)
                    .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { showsControls.toggle() }
            }
            .task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation { showsControls = false }
            }
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            .statusBarHidden()
            .persistentSystemOverlays(.hidden)
    }
}
