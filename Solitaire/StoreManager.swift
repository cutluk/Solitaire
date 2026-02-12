//
//  StoreManager.swift
//  Solitaire
//
//  Manages in-app purchases using StoreKit 2.
//

import StoreKit
import SwiftUI

@MainActor
final class StoreManager: ObservableObject {

    // MARK: - Product IDs

    static let undoProductID = "com.codebycutting.solitaire.undo"

    // MARK: - Published State

    /// Whether the undo feature has been purchased (unlocked forever).
    @Published private(set) var isUndoPurchased: Bool = false

    /// The loaded undo product from the App Store.
    @Published private(set) var undoProduct: Product?

    /// True while products are being loaded from the store.
    @Published private(set) var isLoadingProducts: Bool = false

    /// True while a purchase transaction is in progress.
    @Published var isPurchasing: Bool = false

    /// User-facing error message, if any.
    @Published var errorMessage: String?

    // MARK: - Private

    private var transactionListener: Task<Void, Error>?

    // MARK: - Lifecycle

    init() {
        // Listen for transaction updates (renewals, revocations, family sharing, etc.)
        transactionListener = listenForTransactions()

        // Check for existing entitlements and load products
        Task {
            await restorePurchases()
            await loadProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    /// Fetch the undo product from the App Store.
    func loadProducts() async {
        isLoadingProducts = true
        do {
            let products = try await Product.products(for: [Self.undoProductID])
            undoProduct = products.first
            if undoProduct == nil {
                print("StoreManager: No product found for ID '\(Self.undoProductID)'. "
                      + "Make sure the StoreKit Configuration is set in your scheme "
                      + "(Edit Scheme > Run > Options > StoreKit Configuration).")
            } else {
                print("StoreManager: Loaded product – \(undoProduct!.displayName) (\(undoProduct!.displayPrice))")
            }
        } catch {
            print("StoreManager: Failed to load products – \(error)")
            errorMessage = "Could not load products: \(error.localizedDescription)"
        }
        isLoadingProducts = false
    }

    // MARK: - Purchase

    /// Start a purchase flow for the undo feature.
    func purchaseUndo() async {
        guard let product = undoProduct else {
            errorMessage = "Product not available. Please try again later."
            return
        }

        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isUndoPurchased = true

            case .userCancelled:
                break

            case .pending:
                // Transaction requires approval (e.g., Ask to Buy)
                break

            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }

        isPurchasing = false
    }

    // MARK: - Restore Purchases

    /// Check current entitlements to see if the user already owns the undo feature.
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.undoProductID {
                isUndoPurchased = true
                return
            }
        }
    }

    // MARK: - Transaction Listener

    /// Listen for App Store transaction updates in the background.
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result,
                   transaction.productID == StoreManager.undoProductID {
                    await transaction.finish()
                    await MainActor.run {
                        self?.isUndoPurchased = true
                    }
                }
            }
        }
    }

    // MARK: - Verification

    /// Unwrap a verified transaction or throw on failure.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
