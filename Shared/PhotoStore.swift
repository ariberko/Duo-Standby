import UIKit

/// Keeps one small photo in the shared container for the Photo widget.
enum PhotoStore {
    static var url: URL? {
        AppGroup.containerURL?.appendingPathComponent("standby-photo.jpg")
    }

    static func save(_ image: UIImage) throws {
        guard let url, let data = image.resized(maxSide: 600).jpegData(compressionQuality: 0.85) else { return }
        try data.write(to: url, options: .atomic)
    }

    static func load() -> UIImage? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func remove() {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

extension UIImage {
    func resized(maxSide: CGFloat) -> UIImage {
        let scale = min(1, maxSide / max(size.width, size.height))
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
