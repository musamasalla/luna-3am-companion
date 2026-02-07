//
//  LimitReachedView.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/06.
//

import SwiftUI

/// Soft paywall shown when free users reach their weekly conversation limit
struct LimitReachedView: View {
    @Environment(\.dismiss) private var dismiss
    
    let subscriptionManager: SubscriptionManager
    let usageTracker: UsageTracker
    
    @State private var isPurchasing = false
    
    var body: some View {
        ZStack {
            // Night sky background
            LinearGradient(
                colors: [
                    Color(hex: "0a0a1a"),
                    Color(hex: "1a1a3a"),
                    Color(hex: "0a0a1a")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Luna avatar with gentle glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Message
                VStack(spacing: 16) {
                    Text("You've used your 5 free chats this week")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Upgrade to Luna Premium for unlimited late-night conversations")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Premium benefits
                VStack(alignment: .leading, spacing: 12) {
                    benefitRow(icon: "infinity", text: "Unlimited conversations")
                    benefitRow(icon: "brain.head.profile", text: "Luna remembers you")
                    benefitRow(icon: "bolt.fill", text: "Priority responses")
                    benefitRow(icon: "sparkles", text: "All future features")
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                
                Spacer()
                
                // Upgrade button
                Button {
                    Task {
                        await purchase()
                    }
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Upgrade to Premium")
                                .fontWeight(.semibold)
                            Text("– \(subscriptionManager.priceString)/mo")
                                .fontWeight(.regular)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .disabled(isPurchasing)
                .padding(.horizontal, 24)
                
                // Restore & dismiss
                HStack(spacing: 24) {
                    Button("Restore Purchases") {
                        Task {
                            do {
                                try await subscriptionManager.restorePurchases()
                                if subscriptionManager.isPremium {
                                    dismiss()
                                }
                            } catch {
                                print("Restore failed: \(error)")
                            }
                        }
                    }
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                    
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 32)
            }
        }
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(text)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
    
    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            try await subscriptionManager.purchasePremium()
            if subscriptionManager.isPremium {
                dismiss()
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
}

#Preview {
    LimitReachedView(subscriptionManager: SubscriptionManager(), usageTracker: UsageTracker())
}
