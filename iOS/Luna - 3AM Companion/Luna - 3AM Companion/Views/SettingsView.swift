//
//  SettingsView.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    @State private var showPaywall = false
    @State private var showDeleteConfirmation = false
    @State private var subscriptionManager = SubscriptionManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                StarryNightBackground()
                    .ignoresSafeArea()
                
                List {
                    // Subscription Section
                    Section {
                        Button {
                            if !subscriptionManager.isPremium {
                                showPaywall = true
                            }
                        } label: {
                            SubscriptionStatusRow(manager: subscriptionManager)
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text("Subscription")
                            .foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Rectangle()
                                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                    
                    // Preferences Section
                    Section {
                        Toggle(isOn: $notificationsEnabled) {
                            Label("Nighttime Reminders", systemImage: "bell.fill")
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .tint(Theme.lunaOrange)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    do {
                                        let granted = try await NotificationManager.shared.requestAuthorization()
                                        if granted {
                                            NotificationManager.shared.scheduleNighttimeReminder(enabled: true)
                                        } else {
                                            await MainActor.run {
                                                notificationsEnabled = false
                                            }
                                        }
                                    } catch {
                                        await MainActor.run {
                                            notificationsEnabled = false
                                        }
                                    }
                                }
                            } else {
                                NotificationManager.shared.scheduleNighttimeReminder(enabled: false)
                            }
                        }
                    } header: {
                        Text("Preferences")
                            .foregroundStyle(Theme.textMuted)
                    } footer: {
                        Text("Get a gentle reminder that Luna's awake between 11pm-4am")
                            .foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Rectangle()
                                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                    
                    // About Section
                    Section {
                        if let privacyURL = URL(string: Config.privacyPolicyURL) {
                            Link(destination: privacyURL) {
                                Label("Privacy Policy", systemImage: "hand.raised.fill")
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                        
                        if let termsURL = URL(string: Config.termsOfServiceURL) {
                            Link(destination: termsURL) {
                                Label("Terms of Service", systemImage: "doc.text.fill")
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                        
                        HStack {
                            Label("Version", systemImage: "info.circle.fill")
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(Theme.textMuted)
                        }
                    } header: {
                        Text("About")
                            .foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Rectangle()
                                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                    
                    // Danger Zone
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash.fill")
                                .foregroundStyle(.red)
                        }
                    } header: {
                        Text("Data")
                            .foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Rectangle()
                                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showPaywall) {
                PaywallView(manager: subscriptionManager)
            }
            .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all your conversations with Luna. This action cannot be undone.")
            }
        }
    }
    
    private func deleteAllData() {
        // Delete all conversations
        let descriptor = FetchDescriptor<Conversation>()
        if let conversations = try? modelContext.fetch(descriptor) {
            for conversation in conversations {
                modelContext.delete(conversation)
            }
            try? modelContext.save()
        }
        
        // Reset onboarding
        hasCompletedOnboarding = false
    }
}

// MARK: - Subscription Status Row
private struct SubscriptionStatusRow: View {
    let manager: SubscriptionManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if manager.isPremium {
                    Label("Premium", systemImage: "star.fill")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.premiumGold)
                    
                    Text("Unlimited conversations")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Label("Free Plan", systemImage: "person.fill")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text("5 conversations per week")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            
            Spacer()
            
            if !manager.isPremium {
                Text("Upgrade")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.backgroundPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.premiumGradient)
                    .clipShape(.rect(cornerRadius: Theme.cornerRadiusPill))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}
