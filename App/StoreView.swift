import StoreKit
import SwiftUI

struct StoreView: View {
    @EnvironmentObject private var store: Store
    @State private var purchasing: String?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Make StandBy yours")
                        .font(.title2.bold())
                    Text("Free clocks forever. Unlock packs once and keep them for good. No subscriptions.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("All Access") {
                productRow(
                    id: StoreProducts.allAccess,
                    title: "All Access",
                    subtitle: "Every pack, now and in the future.",
                    symbol: "star.circle.fill",
                    owned: store.hasEverything
                )
            }

            Section("Packs") {
                ForEach(Pack.allCases.filter { $0 != .free }) { pack in
                    productRow(
                        id: pack.productID ?? "",
                        title: pack.title,
                        subtitle: pack.tagline,
                        symbol: pack.symbol,
                        owned: store.isUnlocked(pack)
                    )
                }
            }

            Section("Free") {
                Label {
                    VStack(alignment: .leading) {
                        Text(Pack.free.title).font(.headline)
                        Text(Pack.free.tagline).font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: Pack.free.symbol)
                }
            }

            Section {
                Button {
                    Task { await store.restore() }
                } label: {
                    HStack {
                        Text("Restore Purchases")
                        Spacer()
                        if store.isRestoring { ProgressView() }
                    }
                }
                .disabled(store.isRestoring)
            }
        }
        .navigationTitle("Store")
        .refreshable { await store.loadProducts() }
        .task {
            // Prices can fail to load (no network, products not live yet). Try again when the store opens.
            if store.products.isEmpty { await store.loadProducts() }
            await store.refreshEntitlements()
        }
        .alert("Store", isPresented: Binding(
            get: { store.message != nil },
            set: { if !$0 { store.message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.message ?? "")
        }
        .alert("Purchase failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func productRow(id: String, title: String, subtitle: String, symbol: String, owned: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if owned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            } else if let product = store.product(for: id) {
                Button {
                    Task { await buy(product) }
                } label: {
                    if purchasing == id {
                        ProgressView()
                    } else {
                        Text(product.displayPrice)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(purchasing != nil)
            } else if ScreenshotMode.showsListPrices, let price = Self.listPrices[id] {
                Text(price)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.black)
            } else if store.isLoading {
                ProgressView()
            } else {
                Text("Unavailable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .help("Pull down to try again")
            }
        }
        .padding(.vertical, 4)
    }

    /// Same prices as App Store Connect, only for simulator screenshots.
    private static let listPrices: [String: String] = [
        "com.ariberkowitz.standbystudio.retropack": "$1.99",
        "com.ariberkowitz.standbystudio.space": "$1.99",
        "com.ariberkowitz.standbystudio.pro": "$2.99",
        "com.ariberkowitz.standbystudio.live": "$2.99",
        "com.ariberkowitz.standbystudio.all": "$5.99",
    ]

    private func buy(_ product: Product) async {
        purchasing = product.id
        defer { purchasing = nil }
        do {
            try await store.buy(product)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
