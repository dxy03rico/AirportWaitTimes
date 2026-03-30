import Foundation
import StoreKit
import SwiftUI

/// Manages StoreKit 2 in-app purchases
@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    // Product ID — configure in App Store Connect
    static let fullAccessProductID = "com.airportwaittimes.fullaccess"

    @Published var isUnlocked = false
    @Published var isEarlyAdopter = false
    @Published var totalUserCount = 0
    @Published var priceString: String?
    @Published var product: Product?
    @Published var errorMessage: String?

    private var updateTask: Task<Void, Never>?

    private init() {
        // Load cached state
        isUnlocked = UserDefaults.standard.bool(forKey: "is_unlocked")
        isEarlyAdopter = UserDefaults.standard.bool(forKey: "is_early_adopter")

        // Start listening for transaction updates
        updateTask = Task { await listenForTransactions() }

        // Load product info
        Task { await loadProduct() }
    }

    deinit {
        updateTask?.cancel()
    }

    // MARK: - Load Product
    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.fullAccessProductID])
            if let p = products.first {
                product = p
                priceString = p.displayPrice
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase
    func purchaseFullAccess() async throws {
        guard let product = product else {
            throw StoreError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // Verify with our backend
            try await APIService.shared.verifyPurchase(
                transactionId: String(transaction.id),
                productId: transaction.productID
            )

            // Unlock
            unlock()
            await transaction.finish()

        case .userCancelled:
            throw StoreError.userCancelled

        case .pending:
            throw StoreError.pending

        @unknown default:
            throw StoreError.unknown
        }
    }

    // MARK: - Early Adopter (free unlock for first 100 users)
    func claimEarlyAdopterAccess() async throws {
        try await APIService.shared.claimEarlyAdopter()
        isEarlyAdopter = true
        unlock()
        UserDefaults.standard.set(true, forKey: "is_early_adopter")
    }

    // MARK: - Restore
    func restorePurchases() async {
        // Check existing entitlements
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.fullAccessProductID {
                    unlock()
                    return
                }
            }
        }

        // Also check server-side
        do {
            let status = try await APIService.shared.getUserStatus()
            if status.isPaid || status.isEarlyAdopter {
                unlock()
                if status.isEarlyAdopter {
                    isEarlyAdopter = true
                    UserDefaults.standard.set(true, forKey: "is_early_adopter")
                }
            }
            totalUserCount = status.totalUsers
        } catch {
            print("Server status check failed: \(error)")
        }
    }

    func restorePurchasesSync() {
        Task { await restorePurchases() }
    }

    // MARK: - Transaction listener
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.fullAccessProductID {
                    unlock()
                }
                await transaction.finish()
            }
        }
    }

    // MARK: - Helpers
    private func unlock() {
        isUnlocked = true
        UserDefaults.standard.set(true, forKey: "is_unlocked")
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound: return "Product not available"
        case .userCancelled:   return "Purchase cancelled"
        case .pending:         return "Purchase pending approval"
        case .verificationFailed: return "Purchase verification failed"
        case .unknown:         return "Unknown error occurred"
        }
    }
}
