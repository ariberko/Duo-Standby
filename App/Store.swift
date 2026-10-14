import StoreKit
import SwiftUI
import WidgetKit

/// In-app purchases with StoreKit 2. Every product is a one-time (non-consumable) unlock.
@MainActor
final class Store: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var unlocked: Set<Pack> = Entitlements.unlocked()
    @Published private(set) var isLoading = true
    @Published private(set) var isRestoring = false
    /// A short note for the user after a purchase or restore, shown as an alert.
    @Published var message: String?

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
        case .success(.verified(let transaction)):
            await transaction.finish()
            await refreshEntitlements()
            message = "\(product.displayName) is unlocked. Enjoy!"
        case .success(.unverified(_, let error)):
            await refreshEntitlements()
            message = "The purchase went through, but Apple couldn't verify it on this device (\(error.localizedDescription)). Try Restore Purchases."
        case .pending:
            message = "Your purchase is waiting for approval. It unlocks as soon as it's approved."
        case .userCancelled:
            break
        @unknown default:
            await refreshEntitlements()
        }
    }

    func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        var syncError: Error?
        do {
            try await AppStore.sync()
        } catch {
            syncError = error
        }
        let report = await refreshEntitlements()
        if !report.owned.isEmpty {
            let names = report.owned.map { id in products.first { $0.id == id }?.displayName ?? id }
            message = "Restored: \(names.sorted().joined(separator: ", "))."
        } else if let issue = report.unverified.first {
            message = "Apple found a purchase but couldn't verify it: \(issue)"
        } else if let syncError {
            message = "Couldn't reach the App Store: \(syncError.localizedDescription)"
        } else {
            message = "No purchases found for this Apple Account."
        }
    }

    /// Reads what this Apple Account owns and unlocks the matching packs.
    @discardableResult
    func refreshEntitlements() async -> (owned: Set<String>, unverified: [String]) {
        var owned: Set<String> = []
        var unverified: [String] = []
        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction) where transaction.revocationDate == nil:
                owned.insert(transaction.productID)
            case .unverified(let transaction, let error):
                unverified.append("\(transaction.productID): \(error.localizedDescription)")
            default:
                break
            }
        }
        // Belt and braces: ask for the latest transaction of each product too.
        for id in StoreProducts.all where !owned.contains(id) {
            if case .verified(let transaction)? = await StoreKit.Transaction.latest(for: id),
               transaction.revocationDate == nil {
                owned.insert(id)
            }
        }
        var packs: Set<Pack> = [.free]
        for id in owned {
            packs.formUnion(StoreProducts.packs(for: id))
        }
        if packs != unlocked {
            unlocked = packs
            Entitlements.save(packs)
            WidgetCenter.shared.reloadAllTimelines()
        }
        return (owned, unverified)
    }
}
