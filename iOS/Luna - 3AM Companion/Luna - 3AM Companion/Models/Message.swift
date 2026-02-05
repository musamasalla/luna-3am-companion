//
//  Message.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var content: String
    var isFromLuna: Bool
    var timestamp: Date
    
    var conversation: Conversation?
    
    init(id: UUID = UUID(), content: String, isFromLuna: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isFromLuna = isFromLuna
        self.timestamp = timestamp
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
