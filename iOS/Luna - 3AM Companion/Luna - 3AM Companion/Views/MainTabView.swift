//
//  MainTabView.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var subscriptionManager = SubscriptionManager()
    @State private var usageTracker = UsageTracker()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView(subscriptionManager: subscriptionManager, usageTracker: usageTracker)
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.fill")
                }
                .tag(0)
            
            ConversationHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)
            
            SettingsView(subscriptionManager: subscriptionManager)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(Theme.lunaOrange)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}

