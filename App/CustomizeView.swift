import PhotosUI
import SwiftUI

struct CustomizeView: View {
    @EnvironmentObject private var model: SettingsModel
    @EnvironmentObject private var store: Store
    @State private var pickedPhoto: PhotosPickerItem?

    private let swatches = ["#FF9F0A", "#FF375F", "#BF5AF2", "#0A84FF", "#64D2FF", "#30D158", "#FFD60A", "#FFFFFF"]

    var body: some View {
        Form {
            Section("Preview") {
                TimelineView(.everyMinute) { context in
                    HStack(spacing: 12) {
                        ClockTile(style: .studio, date: context.date, settings: model.settings)
                        ClockTile(style: .minimal, date: context.date, settings: model.settings)
                    }
                }
                .frame(maxHeight: 200)
                .listRowBackground(Color.clear)
            }

            Section("Accent color") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 12) {
                    ForEach(swatches, id: \.self) { hex in
                        Button {
                            model.settings.accentHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if model.settings.accentHex == hex {
                                        Circle().stroke(Color.white, lineWidth: 3)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                ColorPicker("Custom color", selection: Binding(
                    get: { model.settings.accent },
                    set: { model.settings.accentHex = $0.hexString }
                ), supportsOpacity: false)
            }

            Section("Clock") {
                Toggle("24-hour time", isOn: $model.settings.use24Hour)
                Picker("Font", selection: $model.settings.font) {
                    ForEach(FontChoice.allCases) { font in
                        Text(font.title).tag(font)
                    }
                }
            }

            Section {
                TextField("What are you counting down to?", text: $model.settings.countdownTitle)
                DatePicker("Date", selection: $model.settings.countdownDate, displayedComponents: .date)
            } header: {
                Text("Countdown widget")
            } footer: {
                if !store.isUnlocked(.pro) { Text("Countdown is part of the Pro Pack.") }
            }

            Section {
                PhotosPicker(selection: $pickedPhoto, matching: .images) {
                    Label(model.photo == nil ? "Choose photo" : "Change photo", systemImage: "photo")
                }
                if model.photo != nil {
                    Button("Remove photo", role: .destructive) { model.removePhoto() }
                }
            } header: {
                Text("Photo Clock widget")
            } footer: {
                if !store.isUnlocked(.pro) { Text("Photo Clock is part of the Pro Pack.") }
            }
        }
        .navigationTitle("Customize")
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    model.setPhoto(image)
                }
                pickedPhoto = nil
            }
        }
    }
}
