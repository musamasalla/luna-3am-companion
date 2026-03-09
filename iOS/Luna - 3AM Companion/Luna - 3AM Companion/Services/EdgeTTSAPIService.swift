//
//  EdgeTTSAPIService.swift
//  Luna - 3AM Companion
//
//  On-device Edge TTS using SwiftEdgeTTS (no server required)
//

import Foundation
import AVFoundation
import MediaPlayer
import Observation
import os.log
import SwiftEdgeTTS

private let ttsLogger = Logger(subsystem: "com.luna.companion", category: "TTS")

@Observable
class EdgeTTSAPIService: NSObject, AVAudioPlayerDelegate {
    
    // MARK: - Configuration
    
    // Voice options - Edge TTS neural voices
    private let defaultVoice = "en-US-AnaNeural"  // Child-like, warm, expressive
    
    var isSpeaking: Bool = false
    private var audioPlayer: AVAudioPlayer?
    private let ttsService = EdgeTTSService()
    
    override init() {
        super.init()
    }
    
    /// On-device TTS is always configured — no server needed
    var isConfigured: Bool {
        true
    }
    
    // MARK: - TTS Generation
    
    func speak(_ text: String) async throws {
        // Strip emojis
        let sanitizedText = text.unicodeScalars
            .filter { !($0.properties.isEmoji && $0.properties.isEmojiPresentation) }
            .map(String.init)
            .joined()
        
        guard !sanitizedText.isEmpty else { return }
        
        ttsLogger.debug("EdgeTTS: Synthesizing '\(sanitizedText.prefix(50))...'")
        
        // Generate audio file using on-device SwiftEdgeTTS
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("luna_tts_\(UUID().uuidString).mp3")
        
        let audioURL = try await ttsService.synthesize(
            text: sanitizedText,
            voice: defaultVoice,
            outputURL: outputURL,
            rate: "+15%"
        )
        
        // Load audio data and play
        let data = try Data(contentsOf: audioURL)
        try await playAudio(data: data)
        
        // Clean up temp file
        try? FileManager.default.removeItem(at: audioURL)
    }
    
    // MARK: - Remote Command Center
    
    private var activeContinuation: CheckedContinuation<Void, Error>?
    
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
        do {
            try await withCheckedThrowingContinuation { continuation in
                self.activeContinuation = continuation
            }
        } catch {
            player.stop()
            throw error
        }
        
        // Cleanup
        await MainActor.run { self.isSpeaking = false }
        
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
    case invalidURL
    case invalidResponse
    case playbackFailed
    case synthesisFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .playbackFailed:
            return "Audio playback failed"
        case .synthesisFailed(let message):
            return "Speech synthesis failed: \(message)"
        }
    }
}
