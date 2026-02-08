//
//  LoopingVideoPlayer.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import SwiftUI
import AVKit
import os.log

private let videoLogger = Logger(subsystem: "com.luna.companion", category: "Video")

struct LoopingVideoPlayer: View {
    private let player: AVQueuePlayer
    private let looper: AVPlayerLooper?
    
    init(videoName: String, format: String = "mp4") {
        if let url = Bundle.main.url(forResource: videoName, withExtension: format) {
            let item = AVPlayerItem(url: url)
            let player = AVQueuePlayer(playerItem: item)
            self.player = player
            self.looper = AVPlayerLooper(player: player, templateItem: item)
        } else {
            // Fallback empty player if file not found
            self.player = AVQueuePlayer()
            self.looper = nil
            videoLogger.error("Video file \(videoName).\(format) not found in bundle")
        }
    }
    
    var body: some View {
        VideoPlayerView(player: player)
            .onAppear {
                player.play()
            }
            .onDisappear {
                player.pause()
            }
    }
}

// UIKit wrapper for cleaner video presentation (no controls)
private struct VideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = .clear
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }
}
