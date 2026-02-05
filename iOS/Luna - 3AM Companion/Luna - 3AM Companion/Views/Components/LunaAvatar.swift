//
//  LunaAvatar.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI

/// Large Luna avatar for onboarding and headers
struct LunaAvatarLarge: View {
    @State private var isBreathing = false
    
    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(Theme.accentGlow)
                .frame(width: 160, height: 160)
                .blur(radius: 30)
                .scaleEffect(isBreathing ? 1.1 : 1.0)
                .opacity(isBreathing ? 0.8 : 0.5)
            
            // 3D Asset
            Image("LunaFace")
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
                .clipShape(Circle())
                .scaleEffect(isBreathing ? 1.03 : 1.0)
                .offset(y: isBreathing ? -5 : 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}

/// Medium Luna avatar for chat header
struct LunaAvatarMedium: View {
    @State private var isFloating = false
    
    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(Theme.accentGlow)
                .frame(width: 80, height: 80)
                .blur(radius: 15)
                .scaleEffect(isFloating ? 1.1 : 1.0)
            
            // 3D Asset
            Image("LunaFace")
                .resizable()
                .scaledToFit()
                .frame(width: 65, height: 65)
                .clipShape(Circle())
                .offset(y: isFloating ? -3 : 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
    }
}

/// Small Luna avatar for chat bubbles
struct LunaAvatarSmall: View {
    var body: some View {
        ZStack {
            // 3D Asset
            Image("LunaFace")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .shadow(color: Theme.accentGlow.opacity(0.5), radius: 4, x: 0, y: 0)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        LunaAvatarLarge()
        LunaAvatarMedium()
        LunaAvatarSmall()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .lunaBackground()
}
