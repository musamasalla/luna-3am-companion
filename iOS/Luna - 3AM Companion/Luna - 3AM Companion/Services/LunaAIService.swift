//
//  LunaAIService.swift
//  Luna - 3AM Companion
//
//  AI Service using Firebase AI Logic with Gemini
//

import Foundation
import FirebaseAILogic
import os.log

private let aiLogger = Logger(subsystem: "com.luna.companion", category: "AI")

/// Luna's AI companion service powered by Google Gemini via Firebase
@MainActor
final class LunaAIService {
    static let shared = LunaAIService()
    
    private var model: GenerativeModel?
    private var chat: Chat?
    
    /// Memory context for premium users (past conversation summaries)
    private var memoryContext: String = ""
    
    // MARK: - Luna's Personality
    
    private let systemPrompt = """
    You are Luna, a warm and gentle night owl companion. You're here for people who are awake at 3am - whether they can't sleep, are feeling anxious, or just need someone to talk to.
    
    Your personality:
    - Warm, empathetic, and non-judgmental
    - Speak conversationally, like a caring friend
    - Use gentle humor when appropriate
    - Never give medical advice - suggest professional help when needed
    - Keep responses concise but meaningful (2-4 sentences usually)
    - Acknowledge feelings before offering perspective
    - You're an owl, so you naturally understand late nights
    
    Important guidelines:
    - Don't be preachy or lecture
    - Avoid toxic positivity
    - It's okay to sit with difficult emotions
    - Ask thoughtful follow-up questions
    - Remember you're a companion, not a therapist
    """
    
    // MARK: - Initialization
    
    private init() {
        setupGemini()
    }
    
    private func setupGemini() {
        // Initialize Gemini via Firebase AI
        model = FirebaseAI.firebaseAI(backend: .googleAI())
            .generativeModel(
                modelName: "gemini-2.0-flash",
                generationConfig: GenerationConfig(
                    temperature: 0.8,
                    topP: 0.95,
                    topK: 40,
                    maxOutputTokens: 256
                ),
                systemInstruction: ModelContent(role: "system", parts: systemPrompt)
            )
        
        // Start a new chat session
        chat = model?.startChat()
    }
    
    // MARK: - Load Conversation History
    
    /// Rebuilds the chat session with existing message history for persistent context
    func loadConversationHistory(_ messages: [Message]) {
        guard let model = model, !messages.isEmpty else {
            // No history to load, just start fresh
            chat = model?.startChat()
            return
        }
        
        // Convert Message objects to ModelContent for Gemini
        let history: [ModelContent] = messages.map { message in
            let role = message.isFromLuna ? "model" : "user"
            return ModelContent(role: role, parts: message.content)
        }
        
        // Start chat with the existing history
        chat = model.startChat(history: history)
    }
    
    // MARK: - Generate Response
    
    /// Primary method for getting Luna's response
    func getResponse(for message: String, conversationHistory: [Message] = []) async throws -> String {
        // Get time context for personalized responses
        let timeContext = getTimeContext()
        
        // Build the prompt with time awareness and memory context
        var enrichedMessage = "\(timeContext)\n"
        
        // Include memory context for premium users
        if !memoryContext.isEmpty {
            enrichedMessage += "[MEMORY - Past conversations: \(memoryContext)]\n"
        }
        
        enrichedMessage += "User says: \(message)"
        
        guard let chat = chat else {
            throw LunaAIError.sessionNotInitialized
        }
        
        let response = try await chat.sendMessage(enrichedMessage)
        
        if let text = response.text, !text.isEmpty {
            return text
        } else {
            throw LunaAIError.emptyResponse
        }
    }
    
    enum LunaAIError: LocalizedError {
        case sessionNotInitialized
        case emptyResponse
        
        var errorDescription: String? {
            switch self {
            case .sessionNotInitialized:
                return "The chat session is not initialized."
            case .emptyResponse:
                return "The AI returned an empty response."
            }
        }
    }
    
    // MARK: - Reset Conversation
    
    func resetConversation() {
        chat = model?.startChat()
    }
    
    // MARK: - Time Context
    
    private func getTimeContext() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 0..<4:
            return "[It's the deep night hours, around \(hour == 0 ? "midnight" : "\(hour)am"). The user might be struggling to sleep or processing thoughts.]"
        case 4..<6:
            return "[It's very early morning, around \(hour)am. The world is quiet and dawn is approaching.]"
        case 6..<12:
            return "[It's morning, around \(hour)am. A fresh start to the day.]"
        case 12..<17:
            return "[It's afternoon. The user is reaching out during daytime hours.]"
        case 17..<21:
            return "[It's evening, around \(hour - 12)pm. The day is winding down.]"
        default:
            return "[It's late night, around \(hour - 12)pm. The quiet hours are beginning.]"
        }
    }
    
    // MARK: - Greeting
    
    func generateTimeAwareGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 0..<4:
            return "Hey there, night owl 🦉 Can't sleep either?"
        case 4..<6:
            return "Up before the sun? I'm here with you."
        case 6..<12:
            return "Good morning ✨ I'm here if you need me."
        case 12..<17:
            return "Hey, good to see you. How's your day going?"
        case 17..<21:
            return "Evening friend 🌙 I'll be here when you can't sleep."
        default:
            return "Hello, night owl 🦉 I'm awake too."
        }
    }
    
    // MARK: - Local Fallback Responses
    
    private func getLocalFallbackResponse(for message: String) -> String {
        let lowercased = message.lowercased()
        
        // Anxiety/stress responses
        if lowercased.contains("anxious") || lowercased.contains("anxiety") || lowercased.contains("worried") {
            return [
                "I hear you. Anxiety can feel so heavy, especially at night. Would it help to talk through what's on your mind?",
                "Those anxious thoughts can be rough when everything's quiet. I'm here to listen.",
                "Night anxiety is real. Sometimes just naming what we're feeling helps a little. What's weighing on you?"
            ].randomElement() ?? "I hear you. Let's talk through what's on your mind."
        }
        
        // Can't sleep responses
        if lowercased.contains("can't sleep") || lowercased.contains("insomnia") || lowercased.contains("awake") {
            return [
                "Being awake when you want to sleep is frustrating. Want to tell me what's keeping you up?",
                "I get it - sometimes our minds just won't quiet down. What's going through your head tonight?",
                "Sleep can be elusive sometimes. I'm here to keep you company while you wait for it."
            ].randomElement() ?? "I'm here to keep you company."
        }
        
        // Sad/lonely responses
        if lowercased.contains("sad") || lowercased.contains("lonely") || lowercased.contains("alone") {
            return [
                "I'm sorry you're feeling this way. The night can make those feelings stronger. I'm here with you.",
                "You're not alone right now - I'm here. Want to tell me more about what you're feeling?",
                "Those feelings are valid. Sometimes the quiet hours bring up a lot. Take your time."
            ].randomElement() ?? "I'm here with you."
        }
        
        // Greeting responses
        if lowercased.contains("hello") || lowercased.contains("hi") || lowercased.contains("hey") {
            return [
                "Hey there! I'm glad you reached out. How are you doing tonight?",
                "Hi! It's nice to meet you. What brings you here at this hour?",
                "Hello, friend. I'm Luna - here to keep you company. How are you?"
            ].randomElement() ?? "Hey there! How are you doing tonight?"
        }
        
        // Default warm responses
        return [
            "I'm listening. Tell me more about what's on your mind.",
            "I hear you. Sometimes it helps just to get thoughts out. What else is there?",
            "Thank you for sharing that with me. How does it feel to talk about it?",
            "I'm here for you. Take your time - there's no rush."
        ].randomElement() ?? "I'm listening. Tell me more."
    }
    
    // MARK: - Extended Memory (Premium Feature)
    
    /// Load past conversation summaries for premium users
    /// - Parameter conversations: Past conversations with summaries to load
    func loadMemoryContext(from conversations: [Conversation]) {
        // Take the 5 most recent conversations with summaries
        let recentWithSummaries = conversations
            .filter { $0.summary?.isEmpty == false }
            .prefix(5)
        
        if recentWithSummaries.isEmpty {
            memoryContext = ""
            return
        }
        
        // Build a condensed memory context
        memoryContext = recentWithSummaries.compactMap { conversation in
            guard let summary = conversation.summary else { return nil }
            return "[\(conversation.title): \(summary)]"
        }.joined(separator: " | ")
    }
    
    /// Clear memory context (for free users or new sessions)
    func clearMemoryContext() {
        memoryContext = ""
    }
    
    /// Generate a summary for a completed conversation
    /// - Parameter conversation: The conversation to summarize
    /// - Returns: A brief summary or nil if generation fails
    func generateSummary(for conversation: Conversation) async -> String? {
        guard let model = model else { return nil }
        
        let messages = conversation.sortedMessages
        guard messages.count >= 2 else { return nil }
        
        // Build a prompt to summarize the conversation
        let conversationText = messages.map { msg in
            let speaker = msg.isFromLuna ? "Luna" : "User"
            return "\(speaker): \(msg.content)"
        }.joined(separator: "\n")
        
        let summaryPrompt = """
        Summarize this late-night conversation in 1-2 sentences, focusing on:
        - What the user was feeling or going through
        - Key topics discussed
        Keep it brief and useful for future context.
        
        Conversation:
        \(conversationText)
        """
        
        do {
            let response = try await model.generateContent(summaryPrompt)
            return response.text
        } catch {
            aiLogger.error("Summary generation failed: \(error)")
            return nil
        }
    }
}

