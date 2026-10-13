import SwiftUI

/// Edit the name tag and show it full screen for tent mode.
struct NameTagEditorView: View {
    let accent: Color
    var fontDesign: Font.Design = .rounded
    var onSave: () -> Void = {}

    @State private var tag = NameTag.load()
    @State private var showingSign = false
    @State private var saved = SavedNameTags.load()
    @State private var namingPreset = false
    @State private var newPresetName = ""

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

            Section {
                ForEach(saved) { item in
                    Button {
                        tag = item.tag
                    } label: {
                        HStack(spacing: 12) {
                            NameTagView(tag: item.tag, accent: accent, fontDesign: fontDesign)
                                .frame(width: 80, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .foregroundStyle(.primary)
                                Text(item.tag.subtitle.isEmpty ? item.tag.title : "\(item.tag.title) · \(item.tag.subtitle)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    saved.remove(atOffsets: offsets)
                    SavedNameTags.save(saved)
                }
                Button {
                    newPresetName = tag.title
                    namingPreset = true
                } label: {
                    Label("Save current as preset", systemImage: "plus.circle")
                }
            } header: {
                Text("My presets")
            } footer: {
                if saved.isEmpty {
                    Text("Make a tag you like, then save it here to use again with one tap.")
                } else {
                    Text("Swipe left on a preset to delete it.")
                }
            }

            Section("Text") {
                TextField("Name or message", text: $tag.title)
                TextField("Second line (optional)", text: $tag.subtitle)
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(NameTag.colorThemes) { theme in
                            Button {
                                tag.apply(theme)
                            } label: {
                                VStack(spacing: 4) {
                                    Text("Aa")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: theme.text))
                                        .frame(width: 54, height: 40)
                                        .background(Color(hex: theme.background), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .overlay(alignment: .bottom) {
                                            Color(hex: theme.accent).frame(height: 5)
                                                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 8, bottomTrailingRadius: 8))
                                        }
                                    Text(theme.id).font(.caption2)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                ColorPicker("Background", selection: Binding(
                    get: { tag.backgroundColor },
                    set: { tag.backgroundHex = $0.hexString }
                ), supportsOpacity: false)
                ColorPicker("Text", selection: Binding(
                    get: { tag.textColor },
                    set: { tag.textHex = $0.hexString }
                ), supportsOpacity: false)
                ColorPicker("Accent", selection: Binding(
                    get: { tag.accentColor(default: accent) },
                    set: { tag.accentHex = $0.hexString }
                ), supportsOpacity: false)
                if tag.hasCustomColors {
                    Button("Reset to style colors") { tag.resetColors() }
                }
            } header: {
                Text("Colors")
            } footer: {
                Text("Accent is the stripe, glow or Hello frame, depending on the style.")
            }

            Section("Style") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                    ForEach(NameTagStyle.allCases) { style in
                        Button {
                            tag.style = style
                        } label: {
                            VStack(spacing: 6) {
                                NameTagView(tag: styled(style), accent: accent, fontDesign: fontDesign)
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
        .alert("Save preset", isPresented: $namingPreset) {
            TextField("Preset name", text: $newPresetName)
            Button("Save") { savePreset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Give it a short name.")
        }
        .fullScreenCover(isPresented: $showingSign) {
            TentSignView(tag: tag, accent: accent, fontDesign: fontDesign)
        }
    }

    /// The current tag drawn in another style, keeping the user's colors.
    private func styled(_ style: NameTagStyle) -> NameTag {
        var copy = tag
        copy.style = style
        return copy
    }

    private func savePreset() {
        let trimmed = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? (tag.title.isEmpty ? "My preset" : tag.title) : trimmed
        saved.insert(SavedNameTag(name: name, tag: tag), at: 0)
        SavedNameTags.save(saved)
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
