import SwiftUI
import WidgetKit

@MainActor
final class SettingsModel: ObservableObject {
    @Published var settings = StudioSettings.load() {
        didSet {
            guard settings != oldValue else { return }
            settings.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @Published private(set) var photo: UIImage? = PhotoStore.load()

    func setPhoto(_ image: UIImage) {
        try? PhotoStore.save(image)
        photo = PhotoStore.load()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.photo)
    }

    func removePhoto() {
        PhotoStore.remove()
        photo = nil
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.photo)
    }
}
