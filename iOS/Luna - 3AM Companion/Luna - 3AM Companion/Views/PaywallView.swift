//
//  PaywallView.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    let manager: SubscriptionManager
    var onComplete: (() -> Void)? = nil  // Optional callback for onboarding
    var showSkipButton: Bool = false
    var contextMessage: String? = nil  // Optional message like "You've used your 5 free chats"
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isEligibleForTrial = true  // Assume eligible until checked
    
    var body: some View {
        ZStack {
            StarryNightBackground()
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: Theme.spacingLarge) {
                        // Close button
                        HStack {
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Luna avatar
                        LunaAvatarLarge()
                        
                        // Context message (if provided)
                        if let contextMessage = contextMessage {
                            Text(contextMessage)
                                .font(Theme.headlineFont)
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Title
                        VStack(spacing: Theme.spacingSmall) {
                            Text("Unlimited Luna")
                                .font(Theme.titleFont)
                                .foregroundStyle(Theme.textPrimary)
                            
                            Text("Chat whenever you can't sleep")
                                .font(Theme.bodyFont)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        
                        // Features
                        VStack(spacing: Theme.spacingMedium) {
                            FeatureItem(icon: "infinity", text: "Unlimited conversations")
                            FeatureItem(icon: "waveform", text: "Voice Mode conversations")
                            FeatureItem(icon: "brain.head.profile", text: "Luna remembers you")
                            FeatureItem(icon: "bolt.fill", text: "Priority response time")
                            FeatureItem(icon: "sparkles", text: "All future features")
                        }
                        .padding(.vertical, Theme.spacingLarge)
                        .background(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: Theme.cornerRadiusLarge))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                                .stroke(Theme.premiumGold.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Theme.premiumGold.opacity(0.1), radius: 20, x: 0, y: 0)
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Pricing
                        VStack(spacing: Theme.spacingSmall) {
                            if isEligibleForTrial {
                                Text("7-day free trial")
                                    .font(Theme.headlineFont)
                                    .foregroundStyle(Theme.premiumGold)
                                
                                Text("then \(manager.priceString)/month")
                                    .font(Theme.bodyFont)
                                    .foregroundStyle(Theme.textSecondary)
                            } else {
                                Text("\(manager.priceString)/month")
                                    .font(Theme.headlineFont)
                                    .foregroundStyle(Theme.premiumGold)
                                
                                Text("Cancel anytime")
                                    .font(Theme.bodyFont)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        
                        // CTA Button
                        VStack(spacing: Theme.spacingLarge) {
                            VStack(spacing: Theme.spacingMedium) {
                                Button {
                                    Task {
                                        await purchasePremium()
                                    }
                                } label: {
                                    if isLoading || manager.products.isEmpty {
                                        ProgressView()
                                            .tint(Theme.backgroundPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    } else {
                                        Text(isEligibleForTrial ? "Start Free Trial" : "Subscribe Now")
                                            .font(Theme.headlineFont)
                                            .foregroundStyle(Theme.backgroundPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    }
                                }
                                .background(Theme.premiumGradient)
                                .clipShape(.rect(cornerRadius: Theme.cornerRadiusPill))
                                .disabled(isLoading || manager.products.isEmpty)
                                
                                if showSkipButton {
                                    Button {
                                        onComplete?()
                                    } label: {
                                        Text("Continue with Free")
                                            .font(Theme.bodyFont)
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                }
                            }
                            
                            Button {
                                Task {
                                    await restorePurchases()
                                }
                            } label: {
                                Text("Restore Purchases")
                                    .font(Theme.captionFont)
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                        .padding(.horizontal, Theme.spacingLarge)
                        
                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(Theme.captionFont)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Legal footer
                        VStack(spacing: Theme.spacingSmall) {
                            Text("Cancel anytime. Subscription auto-renews.")
                                .font(Theme.smallFont)
                                .foregroundStyle(Theme.textMuted)
                            
                            HStack(spacing: Theme.spacingMedium) {
                                Link("Terms of Service", destination: URL(string: "https://musamasalla.github.io/luna-3am-companion/terms.html")!)
                                Text("·").foregroundStyle(Theme.textMuted)
                                Link("Privacy Policy", destination: URL(string: "https://musamasalla.github.io/luna-3am-companion/privacy.html")!)
                            }
                            .font(Theme.smallFont)
                            .foregroundStyle(Theme.textMuted)
                        }
                        .padding(.bottom, Theme.spacingMedium)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Ensure products are loaded when paywall opens
            if manager.products.isEmpty {
                await manager.loadProducts()
            }
            
            // Check if user is eligible for intro offer (free trial)
            if let product = manager.products.first,
               let subscription = product.subscription {
                isEligibleForTrial = await subscription.isEligibleForIntroOffer
            }
        }
    }
    
    // MARK: - Actions
    
    private func purchasePremium() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await manager.purchasePremium()
            onComplete?()
            dismiss()
        } catch let error as SubscriptionError {
            if error != .userCancelled {
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
        
        isLoading = false
    }
    
    private func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await manager.restorePurchases()
            if manager.isPremium {
                dismiss()
            } else {
                errorMessage = "No active subscription found"
            }
        } catch {
            errorMessage = "Could not restore purchases"
        }
        
        isLoading = false
    }
}

// MARK: - Feature Item
private struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Theme.spacingMedium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.premiumGold)
                .frame(width: 30)
            
            Text(text)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, Theme.spacingXLarge)
    }
}

#Preview {
    PaywallView(manager: SubscriptionManager())
}
