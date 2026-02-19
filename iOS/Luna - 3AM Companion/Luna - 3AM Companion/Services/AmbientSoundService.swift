import Foundation
import AVFoundation
import MediaPlayer
import Observation
import SwiftUI
import UIKit

// MARK: - Sound Types

enum AmbientSound: String, CaseIterable, Identifiable {
    case ocean = "ocean_waves"
    case night = "night_ambience"
    case forest = "forest_sounds"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .ocean: return "Ocean Waves"
        case .night: return "Night Ambience"
        case .forest: return "Forest Sounds"
        }
    }
}

@Observable
class AmbientSoundService: NSObject, AVAudioPlayerDelegate {
    static let shared = AmbientSoundService()
    
    var isPlaying = false
    var volume: Float = 0.5 {
        didSet {
            // Only update immediate volume if not fading
            if fadeTimer == nil {
                player?.volume = volume
            }
        }
    }
    
    // Persist selection
    var selectedSound: AmbientSound {
        didSet {
            if oldValue != selectedSound {
                UserDefaults.standard.set(selectedSound.rawValue, forKey: "selectedAmbientSound")
                changeSound(to: selectedSound)
            }
        }
    }
    
    private var player: AVAudioPlayer?
    private let audioSession = AVAudioSession.sharedInstance()
    private var fadeTimer: Timer?
    private let targetVolume: Float = 0.5
    
    override init() {
        // Load saved sound or default to ocean
        if let savedRaw = UserDefaults.standard.string(forKey: "selectedAmbientSound"),
           let savedSound = AmbientSound(rawValue: savedRaw) {
            self.selectedSound = savedSound
        } else {
            self.selectedSound = .ocean
        }
        
        super.init()
        setupRemoteCommandCenter()
        setupPlayer()
        
        // Handle interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    private func setupPlayer() {
        let filename = selectedSound.rawValue
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("⚠️ AmbientSoundService: '\(filename).mp3' not found in bundle!")
            return
        }
        
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1 // Infinite loop
            newPlayer.prepareToPlay()
            newPlayer.delegate = self
            newPlayer.volume = 0
            self.player = newPlayer
        } catch {
            print("❌ AmbientSoundService: Player init failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Playback Control
    
    func toggle() {
        if isPlaying {
            fadeOutAndStop()
        } else {
            play()
        }
    }
    
    func play() {
        // Re-setup if player is missing (e.g. init failure)
        if player == nil { setupPlayer() }
        
        guard let player = player else { return }
        
        do {
            // Remove .mixWithOthers to ensure we capture the Now Playing Info Center
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            
            player.play()
            
            isPlaying = true
            updateNowPlayingInfo()
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            fadeIn()
            
        } catch {
            print("❌ AmbientSoundService: Play failed: \(error.localizedDescription)")
            isPlaying = false
        }
    }
    
    func changeSound(to sound: AmbientSound) {
        let wasPlaying = isPlaying
        
        // If playing, stop current sound first
        if isPlaying {
            player?.stop()
        }
        
        // Setup new player
        setupPlayer()
        
        // If it was playing, resume with the new sound
        if wasPlaying {
             play()
        } else {
            // Just update metadata if stopped
            updateNowPlayingInfo()
        }
    }
    
    func stop() {
        player?.stop()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        
        isPlaying = false
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        updateNowPlayingInfo() // Update state to paused
        
        // Don't nil out info immediately so the user can see the "Paused" state on lock screen
        // MPNowPlayingInfoCenter.default().nowPlayingInfo = nil 
        // UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    // MARK: - Fading
    
    private func fadeIn() {
        fadeTimer?.invalidate()
        player?.volume = 0
        
        // Cancel any pending fades to prevent fighting
        // Reset volume to 0 to start fade
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.player else { return }
            
            if player.volume < self.targetVolume {
                player.volume = min(self.targetVolume, player.volume + 0.05)
            } else {
                timer.invalidate()
                self.fadeTimer = nil
            }
        }
    }
    
    private func fadeOutAndStop() {
        fadeTimer?.invalidate()
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.player else { return }
            
            if player.volume > 0.05 {
                player.volume -= 0.05
            } else {
                player.volume = 0
                player.stop()
                self.stop() // Full cleanup
                timer.invalidate()
                self.fadeTimer = nil
            }
        }
    }
    
    // MARK: - Remote Commands
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Explicitly enable commands
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.fadeOutAndStop()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.toggle()
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = selectedSound.displayName
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Night Owl Ambient"
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true // Since it's a loop
        
        // Critical: Set playback rate so the UI knows if it's playing
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        if let image = UIImage(named: "AppIcon") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // MARK: - Interruption Handling
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        if type == .began {
            // Player handles pausing automatically, but we can update UI state
            // or explicitly pause if needed.
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && isPlaying {
                    player?.play()
                }
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Should loop infinitely, but if it stops for some reason:
        if flag && isPlaying {
            player.play()
        }
    }
}
