//
//  ChatView.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.createdAt, order: .reverse) private var conversations: [Conversation]
    
    let subscriptionManager: SubscriptionManager
    let usageTracker: UsageTracker
    
    @State private var inputText = ""
    @State private var isLunaTyping = false
    @State private var currentConversation: Conversation?
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isHeaderExpanded = true
    @State private var showLimitPaywall = false
    @State private var isVoiceModeActive = false
    @State private var showVoicePaywall = false
    @FocusState private var isInputFocused: Bool
    
    private var aiService: LunaAIService { LunaAIService.shared }
    
    var body: some View {
        ZStack {
            // New Living Background
            StarryNightBackground()
            
            ZStack(alignment: .bottom) {
                // Messages list (Full Screen)
                ScrollViewReader { proxy in
                    ScrollView {
                        ZStack(alignment: .top) {
                            // Scroll Tracker
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geo.frame(in: .named("scroll")).minY
                                )
                            }
                            .frame(height: 0)
                            
                            LazyVStack(spacing: Theme.spacingMedium) {
                                // Invisible anchor at top for programmatic scrolling
                                Color.clear
                                    .frame(height: 1)
                                    .id("scrollTop")
                                
                                if let conversation = currentConversation {
                                    ForEach(conversation.sortedMessages) { message in
                                        MessageBubble(message: message)
                                            .id(message.id)
                                    }
                                }
                                
                                if isLunaTyping {
                                    TypingIndicator()
                                        .id("typing")
                                }
                            }
                        }
                        // Add padding for header (approx height of expanded state)
                        // This allows content to start below the header but scroll behind it
                        .padding(.top, 160)
                        // Add extra padding at bottom so last message clears the floating input bar
                        .padding(.bottom, 100)
                    }
                    .coordinateSpace(name: "scroll")
                    .scrollDismissesKeyboard(.interactively)
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        // Collapse header immediately when scrolling down
                        // Threshold set to 150 (relative to 160 top padding) to be responsive
                        let shouldExpand = offset > 150
                        if shouldExpand != isHeaderExpanded {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isHeaderExpanded = shouldExpand
                            }
                        }
                    }
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: currentConversation?.messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                // Header (Floating Overlay - Top)
                VStack {
                    FluidHeader(isExpanded: !isInputFocused && isHeaderExpanded)
                        .onTapGesture {
                            isInputFocused = false
                        }
                    Spacer()
                }
                .zIndex(2) // Topmost layer
                
                // Input bar (Floating Overlay - Bottom)
                    ChatInputBar(text: $inputText, isFocused: $isInputFocused, onSend: sendMessage, onVoice: activateVoiceMode, isDisabled: isLunaTyping)
                    .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupConversation()
        }
        .sheet(isPresented: $showLimitPaywall) {
            PaywallView(
                manager: subscriptionManager,
                onComplete: { showLimitPaywall = false },
                contextMessage: "You've used your 5 free chats this week"
            )
        }
        .fullScreenCover(isPresented: $isVoiceModeActive) {
            VoiceChatView()
        }
        .sheet(isPresented: $showVoicePaywall) {
            PaywallView(
                manager: subscriptionManager,
                onComplete: { showVoicePaywall = false },
                contextMessage: "Voice Mode is a Premium feature"
            )
        }
    }
    
    // MARK: - Actions
    
    private func activateVoiceMode() {
        if subscriptionManager.isPremium {
            isVoiceModeActive = true
        } else {
            showVoicePaywall = true
        }
    }
    
    private func setupConversation() {
        // Check if there's an existing conversation from tonight
        let calendar = Calendar.current
        let now = Date()
        
        if let existingConversation = conversations.first(where: { conversation in
            calendar.isDate(conversation.createdAt, inSameDayAs: now)
        }) {
            currentConversation = existingConversation
            
            // Load existing message history into AI service for context
            aiService.loadConversationHistory(existingConversation.sortedMessages)
            
            // Load extended memory for premium users
            if subscriptionManager.isPremium {
                let pastConversations = conversations.filter { !calendar.isDate($0.createdAt, inSameDayAs: now) }
                aiService.loadMemoryContext(from: pastConversations)
            } else {
                aiService.clearMemoryContext()
            }
        } else {
            // Check if free user has reached their weekly limit
            if !usageTracker.canStartConversation(isPremium: subscriptionManager.isPremium) {
                showLimitPaywall = true
                return
            }
            
            // Record this new conversation for usage tracking
            usageTracker.recordConversation()
            
            // Create new conversation for tonight
            let newConversation = Conversation(title: generateConversationTitle())
            modelContext.insert(newConversation)
            try? modelContext.save()
            currentConversation = newConversation
            
            // Reset AI service for fresh conversation
            aiService.resetConversation()
            
            // Send Luna's initial greeting
            Task {
                await sendInitialGreeting()
            }
        }
    }
    
    private func generateConversationTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Night of \(formatter.string(from: Date()))"
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let conversation = currentConversation else { return }
        
        let userMessage = Message(content: inputText.trimmingCharacters(in: .whitespacesAndNewlines), isFromLuna: false)
        userMessage.conversation = conversation
        modelContext.insert(userMessage)
        
        conversation.lastMessageAt = Date()
        try? modelContext.save()
        
        let messageContent = inputText
        inputText = ""
        
        // Dismiss keyboard after sending
        isInputFocused = false
        
        // Get Luna's response
        Task {
            await getLunaResponse(for: messageContent)
        }
    }
    
    private func sendInitialGreeting() async {
        guard let conversation = currentConversation else { return }
        
        // Small delay for natural feel
        try? await Task.sleep(for: .seconds(1))
        
        await MainActor.run {
            isLunaTyping = true
        }
        
        try? await Task.sleep(for: .seconds(1.5))
        
        let greeting = aiService.generateTimeAwareGreeting()
        let lunaMessage = Message(content: greeting, isFromLuna: true)
        lunaMessage.conversation = conversation
        
        await MainActor.run {
            modelContext.insert(lunaMessage)
            conversation.lastMessageAt = Date()
            try? modelContext.save()
            isLunaTyping = false
        }
    }
    
    private func getLunaResponse(for userMessage: String) async {
        guard let conversation = currentConversation else { return }
        
        await MainActor.run {
            isLunaTyping = true
        }
        
        do {
            let response = try await aiService.getResponse(for: userMessage, conversationHistory: conversation.sortedMessages)
            
            let lunaMessage = Message(content: response, isFromLuna: true)
            lunaMessage.conversation = conversation
            
            await MainActor.run {
                modelContext.insert(lunaMessage)
                conversation.lastMessageAt = Date()
                try? modelContext.save()
                isLunaTyping = false
            }
        } catch {
            // Fallback response on error
            let fallbackMessage = Message(content: "I'm having trouble connecting right now, but I'm still here with you. What's on your mind?", isFromLuna: true)
            fallbackMessage.conversation = conversation
            
            await MainActor.run {
                modelContext.insert(fallbackMessage)
                try? modelContext.save()
                isLunaTyping = false
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if isLunaTyping {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        } else if let lastMessage = currentConversation?.sortedMessages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Chat Header (Collapsible)
// Local ChatHeader removed in favor of FluidHeader component

#Preview {
    ChatView(subscriptionManager: SubscriptionManager(), usageTracker: UsageTracker())
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}

