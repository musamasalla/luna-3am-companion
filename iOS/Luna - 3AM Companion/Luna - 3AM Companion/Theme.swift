//
//  Theme.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI

/// Luna's warm, sleepy color palette - optimized for 3am viewing
enum Theme {
    // MARK: - Background Colors
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.08, blue: 0.18),  // Deep midnight blue
            Color(red: 0.12, green: 0.10, blue: 0.22),  // Deep purple-blue
            Color(red: 0.15, green: 0.12, blue: 0.25)   // Slightly lighter purple
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let backgroundPrimary = Color(red: 0.08, green: 0.08, blue: 0.18)
    static let backgroundSecondary = Color(red: 0.12, green: 0.10, blue: 0.22)
    
    // MARK: - Luna's Colors (Warm Orange/Yellow)
    static let lunaOrange = Color(red: 1.0, green: 0.65, blue: 0.35)
    static let lunaYellow = Color(red: 1.0, green: 0.85, blue: 0.45)
    static let lunaBubble = Color(red: 0.95, green: 0.55, blue: 0.25).opacity(0.15)
    static let lunaBubbleBorder = Color(red: 1.0, green: 0.65, blue: 0.35).opacity(0.3)
    
    // MARK: - User Colors (Soft Purple)
    static let userPurple = Color(red: 0.65, green: 0.55, blue: 0.90)
    static let userBubble = Color(red: 0.55, green: 0.45, blue: 0.80).opacity(0.25)
    static let userBubbleBorder = Color(red: 0.65, green: 0.55, blue: 0.90).opacity(0.3)
    
    // MARK: - Text Colors
    static let textPrimary = Color(red: 0.95, green: 0.93, blue: 0.90)  // Soft cream white
    static let textSecondary = Color(red: 0.75, green: 0.72, blue: 0.70)
    static let textMuted = Color(red: 0.55, green: 0.52, blue: 0.50)
    
    // MARK: - Accent Colors
    static let accentPurple = Color(red: 0.55, green: 0.45, blue: 0.80)
    static let accentGlow = Color(red: 1.0, green: 0.75, blue: 0.45).opacity(0.3)
    
    // MARK: - UI Element Colors
    static let inputBackground = Color(red: 0.15, green: 0.13, blue: 0.25)
    static let inputBorder = Color(red: 0.25, green: 0.22, blue: 0.35)
    static let cardBackground = Color(red: 0.12, green: 0.10, blue: 0.20).opacity(0.8)
    
    // MARK: - Subscription Colors
    static let premiumGold = Color(red: 1.0, green: 0.80, blue: 0.40)
    static let premiumGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.75, blue: 0.35),
            Color(red: 1.0, green: 0.55, blue: 0.30)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Typography
    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 17, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 14, weight: .regular, design: .rounded)
    static let smallFont = Font.system(size: 12, weight: .regular, design: .rounded)
    
    // MARK: - Spacing
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 16
    static let spacingLarge: CGFloat = 24
    static let spacingXLarge: CGFloat = 32
    
    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 24
    static let cornerRadiusPill: CGFloat = 100
}

// MARK: - View Extension for Background
extension View {
    func lunaBackground() -> some View {
        self
            .background(Theme.backgroundGradient)
            .preferredColorScheme(.dark)
    }
}
