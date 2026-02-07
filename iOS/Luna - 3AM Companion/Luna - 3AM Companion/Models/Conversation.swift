//
//  Conversation.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import Foundation
import SwiftData

@Model
final class Conversation {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var lastMessageAt: Date
    var title: String
    
    /// AI-generated summary for extended memory (premium feature)
    var summary: String?
    
    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message]
    
    init(id: UUID = UUID(), createdAt: Date = Date(), title: String = "Night Chat") {
        self.id = id
        self.createdAt = createdAt
        self.lastMessageAt = createdAt
        self.title = title
        self.summary = nil
        self.messages = []
    }
    
    var sortedMessages: [Message] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var previewText: String {
        guard let lastMessage = sortedMessages.last else {
            return "No messages yet"
        }
        let prefix = lastMessage.isFromLuna ? "Luna: " : "You: "
        let text = lastMessage.content
        return prefix + (text.count > 50 ? String(text.prefix(50)) + "..." : text)
    }
}
