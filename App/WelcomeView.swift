import SwiftUI

/// Shown once on first launch: how widgets, StandBy and Live scenes work.
struct WelcomeView: View {
    let onDone: () -> Void

    @State private var page = 0

    private struct Page {
        let symbol: String
        let title: String
        let lines: [String]
    }

    private let pages = [
        Page(symbol: "clock.badge.checkmark", title: "Welcome to Duo StandBy",
             lines: ["Clocks, signs and scenes for StandBy, your Home Screen and Lock Screen.",
                     "Free styles are ready to use. Packs unlock more."]),
        Page(symbol: "plus.square.on.square", title: "Add a widget",
             lines: ["Long-press your Home Screen and tap Edit, then Add Widget.",
                     "Search \"Duo StandBy\". Every clock style is its own widget, in small, medium and large."]),
        Page(symbol: "iphone.landscape", title: "Use StandBy",
             lines: ["Charge your iPhone, turn it sideways and let it rest.",
                     "Swipe to the widgets, long-press a stack, tap + and add Duo StandBy."]),
        Page(symbol: "play.tv", title: "Live scenes",
             lines: ["Widgets can't move, so animated scenes play inside the app.",
                     "Add the Live widget: one tap opens your scene full screen, even from StandBy."]),
    ]

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    let item = pages[index]
                    VStack(spacing: 20) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 64, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                        Text(item.title)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                        ForEach(item.lines, id: \.self) { line in
                            Text(line)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 32)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    onDone()
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Start")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .interactiveDismissDisabled(page < pages.count - 1)
        .preferredColorScheme(.dark)
    }
}
