import StoreKit
import SwiftUI
import WidgetKit

/// In-app purchases with StoreKit 2. Every product is a one-time (non-consumable) unlock.
@MainActor
final class Store: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var unlocked: Set<Pack> = Entitlements.unlocked()
    @Published private(set) var isLoading = true

    private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    func isUnlocked(_ pack: Pack) -> Bool { unlocked.contains(pack) }

    var hasEverything: Bool { Set(Pack.allCases).isSubset(of: unlocked) }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: StoreProducts.all).sorted { $0.price < $1.price }
        } catch {
            products = []
        }
    }

    func buy(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                await refreshEntitlements()
            }
        case .pending, .userCancelled:
            break
        @unknown default:
            break
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var packs: Set<Pack> = [.free]
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                packs.formUnion(StoreProducts.packs(for: transaction.productID))
            }
        }
        if packs != unlocked {
            unlocked = packs
            Entitlements.save(packs)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
