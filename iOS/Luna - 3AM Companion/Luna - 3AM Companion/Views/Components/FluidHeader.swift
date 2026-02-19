//
//  FluidHeader.swift
//  Luna - 3AM Companion
//
//  Created by Luna Dev on 2026/02/05.
//

import SwiftUI

struct FluidHeader: View {
    let isExpanded: Bool
    @Namespace private var animation
    
    var body: some View {
        VStack {
            if isExpanded {
                // Expanded State: Large, open, transparent
                expandedView
            } else {
                // Collapsed State: Floating Glass Pill
                collapsedView
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
    }
    
    private var expandedView: some View {
        VStack(spacing: 8) {
            LunaAvatarMedium()
                .matchedGeometryEffect(id: "avatar", in: animation)
            
            VStack(spacing: 4) {
                Text("Luna")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .matchedGeometryEffect(id: "name", in: animation)
                
                Text(timeContextText)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .matchedGeometryEffect(id: "status", in: animation)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            // Subtle top gradient for readability when expanded
            LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .overlay(alignment: .topTrailing) {
            sleepButton
                .padding(.trailing, 20)
                .padding(.top, 40) // Status bar offset
        }
    }
    
    private var collapsedView: some View {
        HStack(spacing: 12) {
            LunaAvatarSmall()
                .matchedGeometryEffect(id: "avatar", in: animation)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Luna")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .matchedGeometryEffect(id: "name", in: animation)
            }
            
            Spacer()
            
            // Sleep Mode Toggle
            sleepButton
                .scaleEffect(0.8)
            
            // Status indicator in collapsed state
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .matchedGeometryEffect(id: "status", in: animation)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.top, 8) // Small offsets from top safely area
    }
    
    private var timeContextText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 1..<4:
            return "Here for the late hours"
        case 4..<6:
            return "Early riser or late nighter?"
        default:
            return "I'll be here when you can't sleep"
        }
    }
    
    // MARK: - Sleep Mode Toggle
    
    private var sleepButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            AmbientSoundService.shared.toggle()
        } label: {
            ZStack {
                if AmbientSoundService.shared.isPlaying {
                    Circle()
                        .fill(Color.indigo.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.indigo.opacity(0.6), lineWidth: 1)
                        )
                }
                
                Image(systemName: AmbientSoundService.shared.isPlaying ? "moon.stars.fill" : "moon.stars")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AmbientSoundService.shared.isPlaying ? Color.indigo : .white.opacity(0.6))
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
    }
}

// Preview Helper
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            FluidHeader(isExpanded: true)
            Spacer()
            FluidHeader(isExpanded: false)
            Spacer()
        }
    }
}
