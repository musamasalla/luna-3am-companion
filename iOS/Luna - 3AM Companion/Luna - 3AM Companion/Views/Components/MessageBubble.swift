//
//  MessageBubble.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    
    private var isFromLuna: Bool { message.isFromLuna }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.spacingSmall) {
            if isFromLuna {
                LunaAvatarSmall()
            } else {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromLuna ? .leading : .trailing, spacing: 4) {
                Text(message.content)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, Theme.spacingMedium)
                    .padding(.vertical, Theme.spacingSmall + 4)
                    .background(bubbleBackground)
                    .clipShape(BubbleShape(isFromLuna: isFromLuna))
                
                Text(message.formattedTime)
                    .font(Theme.smallFont)
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 4)
            }
            
            if isFromLuna {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, Theme.spacingSmall)
    }
    
    private var bubbleBackground: some View {
        Group {
            if isFromLuna {
                Rectangle()
                    .fill(Material.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            } else {
                Rectangle()
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Bubble Shape with Tail
private struct BubbleShape: Shape {
    let isFromLuna: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = Theme.cornerRadiusMedium
        var path = Path()
        
        if isFromLuna {
            // Luna bubble - tail on left
            path.addRoundedRect(
                in: rect,
                cornerSize: CGSize(width: radius, height: radius)
            )
        } else {
            // User bubble - tail on right
            path.addRoundedRect(
                in: rect,
                cornerSize: CGSize(width: radius, height: radius)
            )
        }
        
        return path
    }
}

// MARK: - Typing Indicator
// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.spacingSmall) {
            LunaAvatarSmall()
            
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Theme.lunaOrange.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: isAnimating ? -4 : 0)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            .padding(.horizontal, Theme.spacingMedium)
            .padding(.vertical, Theme.spacingSmall + 4)
            .background(Theme.lunaBubble)
            .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(Theme.lunaBubbleBorder, lineWidth: 1)
            )
            
            Spacer(minLength: 60)
        }
        .padding(.horizontal, Theme.spacingSmall)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubble(message: Message(
            content: "Hey, it's 3am and we're both awake. Want to talk about it?",
            isFromLuna: true
        ))
        
        MessageBubble(message: Message(
            content: "I can't stop thinking about work tomorrow",
            isFromLuna: false
        ))
        
        MessageBubble(message: Message(
            content: "3am work thoughts hit different, don't they? Want to talk about what's on your mind?",
            isFromLuna: true
        ))
        
        TypingIndicator()
    }
    .padding(.vertical)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .lunaBackground()
}
