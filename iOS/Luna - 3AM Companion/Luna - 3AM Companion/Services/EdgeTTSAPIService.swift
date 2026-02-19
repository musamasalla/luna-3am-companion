//
//  EdgeTTSAPIService.swift
//  Luna - 3AM Companion
//
//  Service to call self-hosted Edge TTS server
//

import Foundation
import AVFoundation
import MediaPlayer
import Observation
import os.log

private let ttsLogger = Logger(subsystem: "com.luna.companion", category: "TTS")

@Observable
class EdgeTTSAPIService: NSObject, AVAudioPlayerDelegate {
    
    // MARK: - Configuration
    
    /// Your Edge TTS server URL (set this after deployment)
    /// For local testing: "http://localhost:5050"
    /// For production: "https://your-app.railway.app" or similar
    private let serverURL: String
    private let apiKey: String
    
    // Voice options - Edge TTS neural voices
    // See: https://tts.travisvn.com for full list
    private let defaultVoice = "en-US-AnaNeural"  // Child-like, warm, expressive
    
    var isSpeaking: Bool = false
    private var audioPlayer: AVAudioPlayer?
    
    init(serverURL: String = "https://openai-edge-tts-production-c3c6.up.railway.app", apiKey: String = "luna_tts_key") {
        // Use provided URL or check Info.plist for override
        self.serverURL = serverURL.isEmpty ? (Bundle.main.object(forInfoDictionaryKey: "EDGE_TTS_SERVER_URL") as? String ?? "") : serverURL
        self.apiKey = apiKey
        super.init()
    }
    
    /// Check if the Edge TTS server is configured
    var isConfigured: Bool {
        !serverURL.isEmpty
    }
    
    // MARK: - TTS Generation
    
    func speak(_ text: String) async throws {
        guard isConfigured else {
            throw EdgeTTSError.serverNotConfigured
        }
        
        // Strip emojis
        let sanitizedText = text.unicodeScalars
            .filter { !($0.properties.isEmoji && $0.properties.isEmojiPresentation) }
            .map(String.init)
            .joined()
        
        guard !sanitizedText.isEmpty else { return }
        
        ttsLogger.debug("EdgeTTS API: Requesting speech for '\(sanitizedText.prefix(50))...'")
        
        // Build request
        guard let url = URL(string: "\(serverURL)/v1/audio/speech") else {
            throw EdgeTTSError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let body: [String: Any] = [
            "model": "tts-1",
            "input": sanitizedText,
            "voice": defaultVoice,
            "response_format": "mp3",
            "speed": 1.15
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EdgeTTSError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            ttsLogger.error("EdgeTTS API Error (\(httpResponse.statusCode)): \(errorMessage)")
            throw EdgeTTSError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Play audio
        try await playAudio(data: data)
    }
    
    // MARK: - Remote Command Center
    
    private var activeContinuation: CheckedContinuation<Void, Error>?
    
    // MARK: - Remote Command Center
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Clear previous targets to prevent duplicates
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self, let player = self.audioPlayer, !player.isPlaying else { return .commandFailed }
            player.play()
            
            // Update rate to 1.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            
            Task { @MainActor in self.isSpeaking = true }
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let self = self, let player = self.audioPlayer, player.isPlaying else { return .commandFailed }
            player.pause()
            
            // Update rate to 0.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            
            Task { @MainActor in self.isSpeaking = false }
            return .success
        }
        
        // Register for remote events
        DispatchQueue.main.async {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
    }
    
    private func updateNowPlayingInfo(title: String, duration: TimeInterval = 0) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Luna"
        
        if duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
        }
        
        // Artwork (Optional)
        if let image = UIImage(named: "AppIcon") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // MARK: - Audio Playback
    
    private func playAudio(data: Data) async throws {
        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)
        
        // Request remote events capability
        await MainActor.run {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
        
        // Create player
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        
        guard let player = audioPlayer else {
            throw EdgeTTSError.playbackFailed
        }
        
        // Setup Remote Controls & Info
        setupRemoteTransportControls()
        updateNowPlayingInfo(title: "Speaking...", duration: player.duration)
        
        await MainActor.run { self.isSpeaking = true }
        
        // Play
        player.play()
        
        // Wait for playback to complete using a continuation
        // This replaces the inefficient while loop
        do {
            try await withCheckedThrowingContinuation { continuation in
                self.activeContinuation = continuation
            }
        } catch {
            // Handle cancellation or other errors
            player.stop()
            throw error
        }
        
        // Cleanup is handled in delegate or stop()
        await MainActor.run { self.isSpeaking = false }
        
        // Final cleanup
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        
        await MainActor.run {
            UIApplication.shared.endReceivingRemoteControlEvents()
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        
        Task { @MainActor in
            self.isSpeaking = false
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // Resume continuation to unblock playAudio
        activeContinuation?.resume()
        activeContinuation = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isSpeaking = false
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // Resume continuation to unblock playAudio
        if flag {
            activeContinuation?.resume()
        } else {
            activeContinuation?.resume(throwing: EdgeTTSError.playbackFailed)
        }
        activeContinuation = nil
    }
}

// MARK: - Errors

enum EdgeTTSError: LocalizedError {
    case serverNotConfigured
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .serverNotConfigured:
            return "Edge TTS server URL not configured"
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .playbackFailed:
            return "Audio playback failed"
        }
    }
}
