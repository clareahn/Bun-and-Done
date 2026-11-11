//
//  SoundPlayer.swift
//  Bun and Done
//
//  Created by Clare Ahn on 10/11/2026.
//

import AVFoundation
import Combine

@MainActor
final class SoundPlayer: ObservableObject {
    @Published private(set) var currentSound: FreesoundSound?
    @Published private(set) var isPlaying = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // Change this to search for a different kind of background sound
    private let searchQuery = "calm ambience"

    private let service = FreesoundService()
    // Sounds returned by the API, and which one is currently playing
    private var sounds: [FreesoundSound] = []
    private var currentIndex = 0
    // Stored as properties so they stay in memory while the sound plays
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    func play() async {
        // Only call the API the first time; after that, reuse the list
        if sounds.isEmpty {
            await loadSounds()
        }
        // Loading may have failed, so there could still be no sounds
        guard sounds.isEmpty == false else { return }
        startLooping(sounds[currentIndex])
    }

    func skip() async {
        // Nothing loaded yet, so behave like Play
        guard sounds.isEmpty == false else {
            await play()
            return
        }
        // Go to the next sound, back to the first after the last one
        currentIndex = (currentIndex + 1) % sounds.count
        startLooping(sounds[currentIndex])
    }

    // Keeps currentSound so pressing Play again replays the same sound
    func stop() {
        player?.pause()
        player = nil
        looper = nil
        isPlaying = false
    }

    private func loadSounds() async {
        isLoading = true
        errorMessage = nil
        // Always turn off loading when this function finishes, even after an error
        defer { isLoading = false }

        do {
            // Shuffle so the sounds play in a different order each time
            sounds = try await service.searchSounds(query: searchQuery).shuffled()
            currentIndex = 0
        } catch let error as FreesoundError {
            // Bad response or no results from Freesound
            errorMessage = error.localizedDescription
        } catch {
            // Anything else, most likely no internet connection
            errorMessage = "Couldn't load sounds. Check your internet connection and try again."
        }
    }

    private func startLooping(_ sound: FreesoundSound) {
        // Stop any sound already playing before starting a new one
        stop()

        // Plays sound even when the phone's silent switch is on
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        // AVPlayerLooper replays the sound from the start each time it ends
        let queuePlayer = AVQueuePlayer()
        looper = AVPlayerLooper(player: queuePlayer, templateItem: AVPlayerItem(url: sound.previews.highQualityMP3))
        player = queuePlayer
        queuePlayer.play()

        currentSound = sound
        isPlaying = true
    }
}
