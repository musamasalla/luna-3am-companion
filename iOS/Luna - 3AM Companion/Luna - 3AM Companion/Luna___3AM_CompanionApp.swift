//
//  Luna___3AM_CompanionApp.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI
import SwiftData
import FirebaseCore

// Firebase initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct Luna___3AM_CompanionApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var subscriptionManager = SubscriptionManager()
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(subscriptionManager: subscriptionManager)
            }
        }
        .modelContainer(for: [Conversation.self, Message.self])
    }
}
