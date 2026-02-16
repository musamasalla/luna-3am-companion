//
//  SubscriptionManager.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import Foundation
import StoreKit
import Observation
import os.log

private let storeLogger = Logger(subsystem: "com.luna.companion", category: "Store")

/// Manages premium subscription state using StoreKit 2
@Observable
@MainActor
final class SubscriptionManager {
    private(set) var isPremium: Bool = false
    private(set) var products: [Product] = []
    private(set) var purchaseInProgress = false
    
    // Store the task in a nonisolated way to allow cancellation in deinit
    nonisolated(unsafe) private var updateListenerTask: Task<Void, Never>? = nil
    
    // MARK: - Initialization
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            storeLogger.info("Loading products for ID: \(Config.premiumProductID)")
            products = try await Product.products(for: [Config.premiumProductID])
            storeLogger.info("Loaded \(self.products.count) product(s): \(self.products.map { $0.id })")
        } catch {
            storeLogger.error("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchasePremium() async throws {
        storeLogger.info("purchasePremium called. Products count: \(self.products.count)")
        
        guard let product = products.first else {
            storeLogger.error("No products available — cannot purchase")
            throw SubscriptionError.productNotFound
        }
        
        storeLogger.info("Attempting purchase of: \(product.id) (\(product.displayPrice))")
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            storeLogger.info("Purchase succeeded, verifying...")
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            storeLogger.info("Purchase complete! isPremium: \(self.isPremium)")
            
        case .userCancelled:
            storeLogger.info("User cancelled purchase")
            throw SubscriptionError.userCancelled
            
        case .pending:
            storeLogger.info("Purchase pending approval")
            throw SubscriptionError.pending
            
        @unknown default:
            storeLogger.error("Unknown purchase result")
            throw SubscriptionError.unknown
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Config.premiumProductID {
                    hasActiveSubscription = transaction.revocationDate == nil
                }
            }
        }
        
        isPremium = hasActiveSubscription
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.updateSubscriptionStatus()
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Product Info
    
    var premiumProduct: Product? {
        products.first
    }
    
    var priceString: String {
        premiumProduct?.displayPrice ?? "$2.99"
    }
    
    var trialDuration: String {
        if let subscription = premiumProduct?.subscription,
           let introOffer = subscription.introductoryOffer,
           introOffer.paymentMode == .freeTrial {
            return "\(introOffer.period.value) \(introOffer.period.unit)"
        }
        return "7 days"
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError, Equatable {
    case productNotFound
    case userCancelled
    case pending
    case verificationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found"
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .verificationFailed:
            return "Purchase verification failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
