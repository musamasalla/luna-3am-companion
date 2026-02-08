//
//  SpeechService.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/07.
//

import Foundation
import Speech
import AVFoundation
import Observation
import os.log

private let speechLogger = Logger(subsystem: "com.luna.companion", category: "Speech")

@Observable
class SpeechService: NSObject, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
    
    // MARK: - Properties
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // TTS Services
    private let edgeTTSService = EdgeTTSAPIService()
    private let synthesizer = AVSpeechSynthesizer() // Native fallback
    
    var isListening = false
    var isSpeaking = false
    var transcript = ""
    var error: String?
    
    // Permission States
    var isAuthorizedToRecognize = false
    var isAuthorizedToRecord = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
        speechRecognizer?.delegate = self
        checkPermissions()
        
        // Debug: Log TTS configuration
        if edgeTTSService.isConfigured {
            speechLogger.info("Edge TTS Server: Configured")
        } else {
            speechLogger.info("Edge TTS Server: Not configured, using Native TTS")
        }
    }
    
    // MARK: - Permissions
    
    func checkPermissions() {
        // Speech Recognition
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            Task { @MainActor [weak self] in
                self?.isAuthorizedToRecognize = authStatus == .authorized
            }
        }
        
        // Microphone
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            Task { @MainActor [weak self] in
                self?.isAuthorizedToRecord = allowed
            }
        }
    }
    
    // MARK: - Listening (Speech to Text)
    
    func startListening() throws {
        // Cancel existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure Audio Session for Recording
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Microphone Input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start Recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                Task { @MainActor [weak self] in
                    self?.transcript = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                Task { @MainActor [weak self] in
                    self?.stopListening()
                }
            }
        }
        
        isListening = true
        transcript = ""
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isListening = false
    }
    
    // MARK: - Voice Selection (Native TTS)
    
    private var preferredVoice: AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let englishVoices = voices.filter { $0.language == "en-US" }
        
        // Priority 1: Premium Female
        if let premium = englishVoices.first(where: { $0.quality == .premium && $0.gender == .female }) {
            return premium
        }
        // Priority 2: Enhanced Female
        if let enhanced = englishVoices.first(where: { $0.quality == .enhanced && $0.gender == .female }) {
            return enhanced
        }
        // Priority 3: Any Female
        if let female = englishVoices.first(where: { $0.gender == .female }) {
            return female
        }
        // Fallback
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - Speaking (Text to Speech)
    
    func speak(_ text: String) {
        // Stop any current speech
        stopSpeaking()
        
        // Strip emojis
        let sanitizedText = text.unicodeScalars
            .filter { !($0.properties.isEmoji && $0.properties.isEmojiPresentation) }
            .map(String.init)
            .joined()
        
        guard !sanitizedText.isEmpty else { return }
        
        // Try Edge TTS Server first (if configured)
        if edgeTTSService.isConfigured {
            speechLogger.debug("Attempting Edge TTS Server...")
            
            Task {
                do {
                    await MainActor.run { self.isSpeaking = true }
                    try await edgeTTSService.speak(sanitizedText)
                    
                    // Wait for completion
                    while edgeTTSService.isSpeaking {
                        try await Task.sleep(nanoseconds: 100_000_000)
                    }
                    await MainActor.run { self.isSpeaking = false }
                } catch {
                    speechLogger.error("Edge TTS Server failed: \(error.localizedDescription)")
                    speechLogger.info("Falling back to Native TTS...")
                    await MainActor.run {
                        self.speakNative(sanitizedText)
                    }
                }
            }
        } else {
            // Use Native TTS directly
            speakNative(sanitizedText)
        }
    }
    
    private func speakNative(_ text: String) {
        speechLogger.debug("Native TTS: Speaking '\(text.prefix(50))...'")
        
        // Configure Audio Session for Playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            speechLogger.error("Failed to configure audio session: \(error)")
        }
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.1
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        edgeTTSService.stop()
        isSpeaking = false
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speechLogger.debug("Native TTS: Finished")
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        speechLogger.debug("Native TTS: Started")
        isSpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        speechLogger.debug("Native TTS: Cancelled")
        isSpeaking = false
    }
}

enum SpeechError: Error {
    case requestCreationFailed
    case audioSessionFailed
}
