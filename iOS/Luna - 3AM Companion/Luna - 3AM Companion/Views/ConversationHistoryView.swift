//
//  ConversationHistoryView.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI
import SwiftData

struct ConversationHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.createdAt, order: .reverse) private var conversations: [Conversation]
    
    @State private var selectedConversation: Conversation?
    
    var body: some View {
        NavigationStack {
            ZStack {
                StarryNightBackground()
                    .ignoresSafeArea()
                
                if conversations.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(groupedConversations, id: \.key) { group in
                            Section(header: sectionHeader(group.key)) {
                                ForEach(group.value) { conversation in
                                    Button {
                                        selectedConversation = conversation
                                    } label: {
                                        ConversationRow(conversation: conversation)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(
                                        Rectangle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                            )
                                    )
                                }
                                .onDelete { indexSet in
                                    deleteConversations(in: group.value, at: indexSet)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .sheet(item: $selectedConversation) { conversation in
                ConversationDetailView(conversation: conversation)
            }
        }
    }
    
    // MARK: - Grouped Conversations
    
    private var groupedConversations: [(key: String, value: [Conversation])] {
        let grouped = Dictionary(grouping: conversations) { conversation -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: conversation.createdAt)
        }
        return grouped.sorted { $0.value.first!.createdAt > $1.value.first!.createdAt }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.captionFont)
            .foregroundStyle(Theme.textMuted)
            .textCase(.uppercase)
    }
    
    private func deleteConversations(in conversations: [Conversation], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(conversations[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Conversation Row
private struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: Theme.spacingMedium) {
            LunaAvatarSmall()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                
                Text(conversation.previewText)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                
                Text(conversation.formattedDate)
                    .font(Theme.smallFont)
                    .foregroundStyle(Theme.textMuted)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(.vertical, Theme.spacingSmall)
    }
}

// MARK: - Empty State
private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: Theme.spacingLarge) {
            LunaAvatarMedium()
            
            Text("No conversations yet")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textPrimary)
            
            Text("Your chats with Luna will appear here")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

// MARK: - Conversation Detail View
struct ConversationDetailView: View {
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                StarryNightBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: Theme.spacingMedium) {
                        ForEach(conversation.sortedMessages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding(.vertical, Theme.spacingMedium)
                }
            }
            .navigationTitle(conversation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.lunaOrange)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    ConversationHistoryView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}
