//
//  Config.swift
//  Luna - 3AM Companion
//
//  App configuration constants
//

import Foundation

enum Config {
    // MARK: - Subscription
    static let premiumProductID = "com.musamasalla.luna.premium.monthly"
    
    // MARK: - Free Tier Limits
    static let freeConversationsPerWeek = 5
    static let maxMessageLength = 500
    
    // MARK: - AI Settings
    // Firebase AI Logic is configured via GoogleService-Info.plist
    // No API keys needed here - uses Firebase project authentication
    
    // MARK: - Support
    static let privacyPolicyURL = "https://musamasalla.github.io/luna-3am-companion/privacy.html"
    static let termsOfServiceURL = "https://musamasalla.github.io/luna-3am-companion/terms.html"
    static let supportEmail = "musamasalladev@gmail.com"
}
