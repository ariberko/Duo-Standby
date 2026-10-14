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
                    PurchaseCache.record(transaction)
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
            // Trust the transaction Apple just handed us, even if the device's
            // entitlement list hasn't caught up yet (common in TestFlight).
            PurchaseCache.record(transaction)
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
            message = "The App Store didn't answer (\(syncError.localizedDescription)). If you bought a pack, tap its price again: Apple won't charge twice and it unlocks right away."
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
            case .verified(let transaction):
                PurchaseCache.record(transaction)
            case .unverified(let transaction, let error):
                unverified.append("\(transaction.productID): \(error.localizedDescription)")
            }
        }
        // Belt and braces: ask for the latest transaction of each product too.
        for id in StoreProducts.all where !owned.contains(id) {
            if case .verified(let transaction)? = await StoreKit.Transaction.latest(for: id) {
                PurchaseCache.record(transaction)
            }
        }
        owned.formUnion(PurchaseCache.productIDs)
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

/// Product IDs from verified transactions this device has seen. A pack stays unlocked
/// until Apple reports a refund, so a slow or empty entitlement list can't re-lock it.
enum PurchaseCache {
    private static let key = "ownedProductIDs"

    static var productIDs: Set<String> {
        Set(AppGroup.defaults.stringArray(forKey: key) ?? [])
    }

    static func record(_ transaction: StoreKit.Transaction) {
        var ids = productIDs
        if transaction.revocationDate == nil {
            ids.insert(transaction.productID)
        } else {
            ids.remove(transaction.productID)
        }
        AppGroup.defaults.set(ids.sorted(), forKey: key)
    }
}
