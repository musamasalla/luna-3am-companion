//
//  ConversationManager.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import Foundation
import SwiftData
import SwiftUI

/// Manages conversation CRUD and free tier tracking
@MainActor
final class ConversationManager {
    private var modelContext: ModelContext?
    
    // MARK: - Free Tier Tracking
    // Using UserDefaults directly instead of @AppStorage to avoid @Observable conflict
    private let userDefaults = UserDefaults.standard
    
    private var conversationsThisWeek: Int {
        get { userDefaults.integer(forKey: "conversationsThisWeek") }
        set { userDefaults.set(newValue, forKey: "conversationsThisWeek") }
    }
    
    private var weekStartDateString: String {
        get { userDefaults.string(forKey: "weekStartDate") ?? "" }
        set { userDefaults.set(newValue, forKey: "weekStartDate") }
    }
    
    var remainingFreeConversations: Int {
        resetWeekIfNeeded()
        return max(0, Config.freeConversationsPerWeek - conversationsThisWeek)
    }
    
    var hasReachedFreeLimit: Bool {
        resetWeekIfNeeded()
        return conversationsThisWeek >= Config.freeConversationsPerWeek
    }
    
    // MARK: - Initialization
    
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Conversation Management
    
    func createConversation(title: String = "Night Chat") -> Conversation? {
        guard let context = modelContext else { return nil }
        
        // Check free tier limit
        if hasReachedFreeLimit {
            return nil // Trigger paywall
        }
        
        let conversation = Conversation(title: title)
        context.insert(conversation)
        
        // Increment weekly counter
        incrementConversationCount()
        
        try? context.save()
        return conversation
    }
    
    func deleteConversation(_ conversation: Conversation) {
        guard let context = modelContext else { return }
        context.delete(conversation)
        try? context.save()
    }
    
    func addMessage(_ content: String, isFromLuna: Bool, to conversation: Conversation) {
        guard let context = modelContext else { return }
        
        let message = Message(content: content, isFromLuna: isFromLuna)
        message.conversation = conversation
        context.insert(message)
        
        conversation.lastMessageAt = Date()
        try? context.save()
    }
    
    // MARK: - Week Tracking
    
    private func resetWeekIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        
        // Get current week's Monday
        guard let currentMonday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return
        }
        
        let formatter = ISO8601DateFormatter()
        let currentMondayString = formatter.string(from: currentMonday)
        
        if weekStartDateString != currentMondayString {
            // New week - reset counter
            weekStartDateString = currentMondayString
            conversationsThisWeek = 0
        }
    }
    
    private func incrementConversationCount() {
        resetWeekIfNeeded()
        conversationsThisWeek += 1
    }
    
    // MARK: - Conversation Queries
    
    func getTonightConversation() -> Conversation? {
        guard let context = modelContext else { return nil }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate { $0.createdAt >= startOfDay },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try? context.fetch(descriptor).first
    }
}
