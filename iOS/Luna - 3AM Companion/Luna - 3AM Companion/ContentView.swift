//
//  ContentView.swift
//  Luna - 3AM Companion
//
//  This file is no longer used - the app uses ChatView as its main view.
//  Keeping for legacy reference only.
//

import SwiftUI

struct ContentView: View {
    @State private var subscriptionManager = SubscriptionManager()
    @State private var usageTracker = UsageTracker()
    
    var body: some View {
        ChatView(subscriptionManager: subscriptionManager, usageTracker: usageTracker)
    }
}

#Preview {
    ContentView()
}
