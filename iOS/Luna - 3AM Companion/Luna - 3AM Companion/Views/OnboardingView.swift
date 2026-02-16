//
//  OnboardingView.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasAcceptedAIDataSharing") private var hasAcceptedAIDataSharing = false
    @State private var currentPage = 0
    let subscriptionManager: SubscriptionManager
    
    var body: some View {
        ZStack {
            StarryNightBackground()
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)
                
                WhenToUsePage()
                    .tag(1)
                
                HowItWorksPage()
                    .tag(2)
                
                // AI Data Consent (Apple Guideline 5.1.1/5.1.2)
                AIConsentView {
                    withAnimation {
                        currentPage = 4
                    }
                }
                .tag(3)
                
                // Use the proper PaywallView with StoreKit integration
                // Only allow navigating here IF consent is given
                if hasAcceptedAIDataSharing {
                    OnboardingPaywallWrapper(
                        manager: subscriptionManager,
                        onComplete: completeOnboarding
                    )
                    .tag(4)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .preferredColorScheme(.dark)
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Welcome Page
private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: Theme.spacingLarge) {
            Spacer()
            
            // Luna video greeting
            LoopingVideoPlayer(videoName: "luna_welcome")
                .frame(width: 320, height: 320)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.accentGlow.opacity(0.3), lineWidth: 1))
                .shadow(color: Theme.accentGlow.opacity(0.6), radius: 30, x: 0, y: 0)
            
            Text("Hi, I'm Luna 🦉")
                .font(Theme.titleFont)
                .foregroundStyle(Theme.textPrimary)
            
            VStack(spacing: Theme.spacingSmall) {
                Text("I'm awake when you can't sleep")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                
                Text("No meditation, no pressure - just company")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.spacingLarge)
            
            Spacer()
            
            SwipeHint()
        }
        .padding()
    }
}

// MARK: - When To Use Page
private struct WhenToUsePage: View {
    var body: some View {
        VStack(spacing: Theme.spacingLarge) {
            Spacer()
            
            Text("Use Luna when:")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textPrimary)
            
            VStack(alignment: .leading, spacing: Theme.spacingMedium) {
                UseCaseRow(icon: "moon.fill", text: "You can't fall asleep")
                UseCaseRow(icon: "clock.fill", text: "You wake up at 3am and can't turn your brain off")
                UseCaseRow(icon: "heart.fill", text: "You feel alone in the middle of the night")
                UseCaseRow(icon: "person.2.fill", text: "You just need someone who's awake too")
            }
            .padding(.horizontal, Theme.spacingMedium)
            
            Spacer()
            
            SwipeHint()
        }
        .padding()
    }
}

// MARK: - How It Works Page
private struct HowItWorksPage: View {
    var body: some View {
        VStack(spacing: Theme.spacingLarge) {
            Spacer()
            
            LunaAvatarMedium()
            
            Text("Just chat with me")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textPrimary)
            
            VStack(spacing: Theme.spacingMedium) {
                Text("Tell me what's on your mind, or we can talk about random stuff")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                
                Text("I'm not here to fix you - just keep you company")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.lunaOrange)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.spacingLarge)
            
            Spacer()
            
            SwipeHint()
        }
        .padding()
    }
}

// MARK: - Onboarding Paywall Wrapper
private struct OnboardingPaywallWrapper: View {
    let manager: SubscriptionManager
    var onComplete: () -> Void
    
    var body: some View {
        // Reuse the compliant PaywallView with unified layout
        PaywallView(
            manager: manager,
            onComplete: onComplete,
            showSkipButton: true
        )
    }
}

// MARK: - Supporting Components
private struct UseCaseRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Theme.spacingMedium) {
            Image(systemName: icon)
                .foregroundStyle(Theme.lunaOrange)
                .frame(width: 24)
            
            Text(text)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct SwipeHint: View {
    var body: some View {
        Text("Swipe to continue →")
            .font(Theme.captionFont)
            .foregroundStyle(Theme.textMuted)
            .padding(.bottom, Theme.spacingXLarge)
    }
}

#Preview {
    OnboardingView(subscriptionManager: SubscriptionManager())
}
