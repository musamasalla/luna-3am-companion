//
//  AIConsentView.swift
//  Luna - 3AM Companion
//
//  AI data sharing consent for onboarding (Apple Guideline 5.1.1/5.1.2)
//

import SwiftUI

struct AIConsentView: View {
    @AppStorage("hasAcceptedAIDataSharing") private var hasAcceptedAIDataSharing = false
    @State private var showPrivacyPolicy = false
    
    var body: some View {
        VStack(spacing: Theme.spacingLarge) {
            Spacer()
            
            // Icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundStyle(Theme.premiumGold)
                .shadow(color: Theme.premiumGold.opacity(0.4), radius: 10)
            
            Text("Your Privacy Matters")
                .font(Theme.titleFont)
                .foregroundStyle(Theme.textPrimary)
            
            Text("Before we chat, here's how Luna works:")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
            
            // Data disclosure cards
            VStack(spacing: Theme.spacingSmall) {
                DataDisclosureRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Your Messages",
                    detail: "Text you type or speak is sent to Google (Gemini AI) to generate Luna's responses."
                )
                
                DataDisclosureRow(
                    icon: "waveform",
                    title: "Voice Mode",
                    detail: "In voice mode, Luna's responses are converted to speech using Microsoft Edge TTS."
                )
                
                DataDisclosureRow(
                    icon: "iphone",
                    title: "Stored Locally",
                    detail: "Your conversations are saved only on your device. We never store them on our servers."
                )
                
                DataDisclosureRow(
                    icon: "xmark.shield.fill",
                    title: "Not Collected",
                    detail: "We don't access your contacts, photos, location, or any other personal data."
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Privacy policy link
            Button {
                showPrivacyPolicy = true
            } label: {
                Label("Read Full Privacy Policy", systemImage: "doc.text")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.lunaOrange)
            }
            
            // Consent button
            Button {
                withAnimation {
                    hasAcceptedAIDataSharing = true
                }
            } label: {
                Text("I Understand & Agree")
                    .font(Theme.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.premiumGold)
                    .foregroundStyle(.black)
                    .clipShape(.rect(cornerRadius: Theme.cornerRadiusLarge))
            }
            .padding(.horizontal)
            .padding(.bottom, Theme.spacingXLarge)
        }
        .padding()
        .sheet(isPresented: $showPrivacyPolicy) {
            SafariView(url: URL(string: "https://musamasalla.github.io/luna-3am-companion/privacy.html")!)
        }
    }
}

// MARK: - Data Disclosure Row
private struct DataDisclosureRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacingMedium) {
            Image(systemName: icon)
                .foregroundStyle(Theme.lunaOrange)
                .frame(width: 24)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.bodyFont.bold())
                    .foregroundStyle(Theme.textPrimary)
                
                Text(detail)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
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

// MARK: - Safari View for Privacy Policy
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
            vc.dismiss(animated: true)
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: some UIViewController, context: Context) {}
}

#Preview {
    ZStack {
        StarryNightBackground()
            .ignoresSafeArea()
        AIConsentView()
    }
}
