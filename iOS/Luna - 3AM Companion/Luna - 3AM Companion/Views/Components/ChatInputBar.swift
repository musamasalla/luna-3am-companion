//
//  ChatInputBar.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void
    var onVoice: (() -> Void)? = nil
    var isDisabled: Bool = false
    
    private let maxCharacters = 500
    
    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.spacingSmall) {
            // Voice Mode Button (if enabled)
            if let onVoice = onVoice {
                Button(action: onVoice) {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(8)
                        .background(Theme.inputBackground)
                        .clipShape(Circle())
                }
                .disabled(isDisabled)
            }
            
            // Text input field
            TextField("What's on your mind?", text: $text, axis: .vertical)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1...5)
                .focused(isFocused)
                .padding(.horizontal, Theme.spacingMedium)
                .padding(.vertical, Theme.spacingSmall + 4)
                .background(Theme.inputBackground)
                .clipShape(.rect(cornerRadius: Theme.cornerRadiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                        .stroke(isFocused.wrappedValue ? Theme.lunaOrange.opacity(0.5) : Theme.inputBorder, lineWidth: 1)
                )
                .onChange(of: text) { _, newValue in
                    if newValue.count > maxCharacters {
                        text = String(newValue.prefix(maxCharacters))
                    }
                }
            
            // Send button
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(canSend ? Theme.lunaOrange : Theme.textMuted)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, Theme.spacingMedium)
        .padding(.vertical, Theme.spacingSmall)
        .background(Material.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, Theme.spacingSmall)
        .padding(.bottom, Theme.spacingSmall)
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDisabled
    }
    
    private func sendMessage() {
        guard canSend else { return }
        onSend()
    }
}

// MARK: - Character Counter (Optional)
struct CharacterCounter: View {
    let current: Int
    let max: Int
    
    var body: some View {
        Text("\(current)/\(max)")
            .font(Theme.smallFont)
            .foregroundStyle(current > max - 50 ? Theme.lunaOrange : Theme.textMuted)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @FocusState private var isFocused: Bool
        var body: some View {
            VStack {
                Spacer()
                ChatInputBar(text: .constant(""), isFocused: $isFocused) {
                    print("Send tapped")
                }
            }
            .lunaBackground()
        }
    }
    return PreviewWrapper()
}
