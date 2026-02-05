//
//  StarryNightBackground.swift
//  Luna - 3AM Companion
//
//  Created by Luna Dev on 2026/02/05.
//

import SwiftUI

struct StarryNightBackground: View {
    @State private var isAnimating = false
    
    // Generate random stars once
    private let stars: [Star] = (0..<50).map { _ in
        Star(
            x: Double.random(in: 0...1),
            y: Double.random(in: 0...1),
            size: Double.random(in: 1...3),
            blinkDuration: Double.random(in: 2...5),
            delay: Double.random(in: 0...2)
        )
    }
    
    var body: some View {
        ZStack {
            // 1. Deep Base Gradient
            LinearGradient(
                colors: [
                    Color(hex: "0B0B15"), // Deepest midnight
                    Color(hex: "1A1A2E"), // Dark purple-blue
                    Color(hex: "13132B")  // Deep mulberry
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 2. Aurora Glow (Subtle)
            GeometryReader { geo in
                Circle()
                    .fill(Color(hex: "4A4A8A").opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .position(x: isAnimating ? geo.size.width * 0.2 : geo.size.width * 0.8, y: geo.size.height * 0.3)
                    .animation(
                        .easeInOut(duration: 20).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Circle()
                    .fill(Color(hex: "2D2D56").opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .position(x: isAnimating ? geo.size.width * 0.8 : geo.size.width * 0.2, y: geo.size.height * 0.7)
                    .animation(
                        .easeInOut(duration: 25).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .ignoresSafeArea()
            
            // 3. Twinkling Stars
            GeometryReader { geo in
                ForEach(0..<stars.count, id: \.self) { index in
                    let star = stars[index]
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(
                            x: geo.size.width * star.x,
                            y: geo.size.height * star.y
                        )
                        .opacity(isAnimating ? 1 : 0.2)
                        .animation(
                            .easeInOut(duration: star.blinkDuration)
                            .repeatForever(autoreverses: true)
                            .delay(star.delay),
                            value: isAnimating
                        )
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    struct Star {
        let x: Double
        let y: Double
        let size: Double
        let blinkDuration: Double
        let delay: Double
    }
}

// Helper for hex colors without full Theme dependency if needed, 
// though typically we'd add these to Theme.swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    StarryNightBackground()
}
