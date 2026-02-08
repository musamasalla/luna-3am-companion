//
//  VoiceChatView.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/07.
//

import SwiftUI
import AVFoundation

struct VoiceChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var speechService = SpeechService()
    @State private var pulseAmount: CGFloat = 1.0
    @State private var isProcessing = false
    @State private var showPermissionAlert = false
    
    // Services
    private let lunaService = LunaAIService.shared
    
    var body: some View {
        ZStack {
            // Background
            StarryNightBackground()
                .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button {
                        stopAndDismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title2)
                            .foregroundStyle(Theme.textSecondary)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Main Interaction Area
                ZStack {
                    // Ripple Effect (when listening or speaking)
                    if speechService.isListening || speechService.isSpeaking {
                        Circle()
                            .stroke(Theme.accentGlow.opacity(0.3), lineWidth: 2)
                            .frame(width: 200, height: 200)
                            .scaleEffect(pulseAmount)
                            .opacity(2 - pulseAmount)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                    pulseAmount = 2.0
                                }
                            }
                    }
                    
                    // Avatar
                    LunaAvatarLarge()
                        .scaleEffect(isProcessing ? 1.1 : 1.0)
                        .scaleEffect(speechService.isSpeaking ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: isProcessing)
                        .animation(.easeInOut(duration: 0.2).repeatForever(), value: speechService.isSpeaking)
                }
                
                Spacer()
                
                // Status & Transcript
                VStack(spacing: 20) {
                    // Status Text
                    Text(statusText)
                        .font(Theme.headlineFont)
                        .foregroundStyle(Theme.premiumGold)
                        .transition(.opacity)
                    
                    // Live Transcript
                    if !speechService.transcript.isEmpty {
                        Text(speechService.transcript)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal)
                    }
                }
                .frame(height: 100)
                
                Spacer()
                
                // Controls
                // Controls
                ZStack {
                    // Center: Mic Control (Main Action)
                    Button {
                        toggleListening()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(micButtonColor)
                                .frame(width: 80, height: 80)
                                .shadow(color: micButtonColor.opacity(0.5), radius: 10)
                            
                            Image(systemName: micButtonIcon)
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.bottom, 40)
                
                // Error Overlay
                if let error = errorMessage {
                    Text(error)
                        .font(Theme.captionFont)
                        .foregroundStyle(.red)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                        .onTapGesture {
                            errorMessage = nil
                        }
                }
            }
        }
        .onAppear {
            startSession()
        }
        .onDisappear {
            speechService.stopListening()
            speechService.stopSpeaking()
        }
        .onChange(of: speechService.transcript) { _, newTranscript in
            resetSilenceTimer()
        }
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Settings", role: .cancel) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable microphone access in Settings to talk to Luna.")
        }
    }
    
    // MARK: - Logic
    
    @State private var errorMessage: String?
    
    // Timer to detect end of speech
    @State private var silenceTimer: Timer?
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        guard speechService.isListening, !speechService.transcript.isEmpty else { return }
        
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            submitQuery()
        }
    }
    
    private func startSession() {
        errorMessage = nil
        if !speechService.isAuthorizedToRecord {
            speechService.checkPermissions()
        }
        
        if speechService.isAuthorizedToRecord {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startListening()
            }
        }
    }
    
    private func toggleListening() {
        errorMessage = nil
        if speechService.isListening {
            if !speechService.transcript.isEmpty {
                submitQuery()
            } else {
                stopListening()
            }
        } else if speechService.isSpeaking {
            speechService.stopSpeaking()
            startListening()
        } else {
            startListening()
        }
    }
    
    private func startListening() {
        guard speechService.isAuthorizedToRecord else {
            showPermissionAlert = true
            return
        }
        
        speechService.stopSpeaking()
        
        do {
            try speechService.startListening()
        } catch {
            errorMessage = "Failed to listen: \(error.localizedDescription)"
        }
    }
    
    private func stopListening() {
        speechService.stopListening()
        silenceTimer?.invalidate()
    }
    
    private func submitQuery() {
        let query = speechService.transcript
        stopListening()
        
        guard !query.isEmpty else { return }
        
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await lunaService.getResponse(for: query)
                
                await MainActor.run {
                    isProcessing = false
                    speechService.speak(response)
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "AI Error: \(error.localizedDescription)"
                    speechService.speak("I had trouble thinking. Checked the screen for details.")
                }
            }
        }
    }
    
    private func stopAndDismiss() {
        speechService.stopListening()
        speechService.stopSpeaking()
        dismiss()
    }
    
    // MARK: - Computed Props
    
    private var statusText: String {
        if isProcessing {
            return "Thinking..."
        } else if speechService.isSpeaking {
            return "Luna is speaking..."
        } else if speechService.isListening {
            return "Listening..."
        } else {
            return "Tap to Speak"
        }
    }
    
    private var micButtonColor: Color {
        if isProcessing {
            return Theme.textMuted
        } else if speechService.isListening {
            return Color.red
        } else if speechService.isSpeaking {
            return Theme.backgroundPrimary
        } else {
            return Theme.premiumGold
        }
    }
    
    private var micButtonIcon: String {
        if isProcessing {
            return "hourglass"
        } else if speechService.isListening {
            return "stop.fill"
        } else if speechService.isSpeaking {
            return "mic.fill"
        } else {
            return "mic.fill"
        }
    }
}

#Preview {
    VoiceChatView()
}
