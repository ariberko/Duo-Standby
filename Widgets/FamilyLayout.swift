import SwiftUI
import WidgetKit

/// Small widgets show just the face. Medium widgets put the face on the left and details on the right.
struct FaceWithDetails<Face: View, Details: View>: View {
    @Environment(\.widgetFamily) private var family
    private let padding: CGFloat
    private let face: Face
    private let details: Details

    init(padding: CGFloat = 12, @ViewBuilder face: () -> Face, @ViewBuilder details: () -> Details) {
        self.padding = padding
        self.face = face()
        self.details = details()
    }

    var body: some View {
        if family == .systemMedium {
            HStack(spacing: 16) {
                ScaledToFit { face }
                    .aspectRatio(1, contentMode: .fit)
                details
            }
            .padding(12)
        } else {
            face.padding(padding)
        }
    }
}
