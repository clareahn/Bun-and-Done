//
//  SoundPlayerView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 10/11/2026.
//

import SwiftUI
// Opens from the Focus screen to play, skip and stop background sounds
struct SoundPlayerView: View {
    @EnvironmentObject private var soundPlayer: SoundPlayer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Change icon to a speaker while a sound is playing
            Image(systemName: soundPlayer.isPlaying ? "speaker.wave.2.fill" : "music.note")
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 4) {
                // Current sound name and its creator, which also acts as the Freesound credit
                Text(soundPlayer.currentSound?.name ?? "Focus background sounds")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)

                if let sound = soundPlayer.currentSound {
                    Text("by \(sound.username) on Freesound")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                }
            }
            // Shown while the sound list is being fetched from the API
            if soundPlayer.isLoading {
                ProgressView("Loading sounds…")
            }
            // Shown if the API call fails, e.g. no internet connection
            if let message = soundPlayer.errorMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                    .multilineTextAlignment(.center)
            }
            // Playback controls, each disabled when it can't do anything
            HStack(spacing: 32) {
                Button("Stop", systemImage: "stop.fill") {
                    soundPlayer.stop()
                }
                .disabled(soundPlayer.isPlaying == false)
                
                // Play and Skip may call the API, so they run in a Task
                Button("Play", systemImage: "play.fill") {
                    Task { await soundPlayer.play() }
                }
                .disabled(soundPlayer.isPlaying || soundPlayer.isLoading)

                Button("Skip", systemImage: "forward.fill") {
                    Task { await soundPlayer.skip() }
                }
                .disabled(soundPlayer.isLoading)
            }
            // Shows icons only; VoiceOver still reads the button titles
            .labelStyle(.iconOnly)
            .font(.title)
            .foregroundStyle(Color.accentColor)

            Text("Sounds will stop playing when your focus session ends.")
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Focus Background Sounds")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SoundPlayerView()
    }
    .environmentObject(SoundPlayer())
}
