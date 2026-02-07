//
//  UsageTracker.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/06.
//

import Foundation
import SwiftUI

/// Tracks conversation usage for free tier limits
@Observable
@MainActor
final class UsageTracker {
    // MARK: - Constants
    
    static let freeWeeklyLimit = 5
    
    // MARK: - Stored Properties (UserDefaults)
    
    @ObservationIgnored
    @AppStorage("weeklyConversationCount") private var storedCount: Int = 0
    
    @ObservationIgnored
    @AppStorage("weekStartTimestamp") private var weekStartTimestamp: Double = Date().timeIntervalSince1970
    
    // MARK: - Computed Properties
    
    var conversationsUsedThisWeek: Int {
        resetIfNewWeek()
        return storedCount
    }
    
    var conversationsRemaining: Int {
        max(0, Self.freeWeeklyLimit - conversationsUsedThisWeek)
    }
    
    var hasReachedLimit: Bool {
        conversationsUsedThisWeek >= Self.freeWeeklyLimit
    }
    
    // MARK: - Methods
    
    /// Check if user can start a new conversation
    func canStartConversation(isPremium: Bool) -> Bool {
        if isPremium { return true }
        resetIfNewWeek()
        return storedCount < Self.freeWeeklyLimit
    }
    
    /// Record that a conversation was started
    func recordConversation() {
        resetIfNewWeek()
        storedCount += 1
    }
    
    /// Reset count if we're in a new week (Monday as start)
    private func resetIfNewWeek() {
        let weekStart = Date(timeIntervalSince1970: weekStartTimestamp)
        let calendar = Calendar.current
        
        // Check if current date is in a different week than stored week start
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        let storedWeek = calendar.component(.weekOfYear, from: weekStart)
        let currentYear = calendar.component(.yearForWeekOfYear, from: Date())
        let storedYear = calendar.component(.yearForWeekOfYear, from: weekStart)
        
        if currentWeek != storedWeek || currentYear != storedYear {
            // New week - reset counter
            storedCount = 0
            weekStartTimestamp = Date().timeIntervalSince1970
        }
    }
}
