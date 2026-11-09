//
//  FocusView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 9/11/2026.
//

import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var focusTimer: FocusTimer

    @State private var focusLength = 25
    @State private var breakLength = 5

    private let focusOptions = [1, 25, 45, 60]
    private let breakOptions = [5, 10, 15]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                FocusRingView(progress: focusTimer.progress,
                              isBreak: focusTimer.phase == .onBreak)
                    .frame(width: 240, height: 240)

                Text(focusTimer.phase == .idle ? "\(focusLength):00" : focusTimer.timeText)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.primaryText)

                if focusTimer.phase == .idle {
                    setupControls
                } else {
                    runningControls
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            // Screen closes in?
            // Temporary fix for now
        }
        .background(Color.appBackground)
        .navigationTitle("Focus")
        .onAppear {
            focusLength = taskStore.settings.focusLength
            breakLength = taskStore.settings.breakLength
        }
    }

    private var setupControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Focus length · min").font(.subheadline.weight(.semibold))
            Picker("Focus length", selection: $focusLength) {
                ForEach(focusOptions, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)

            Text("Break length · min").font(.subheadline.weight(.semibold))
            Picker("Break length", selection: $breakLength) {
                ForEach(breakOptions, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)

            Button {
                focusTimer.startFocus(focusMinutes: focusLength, breakMinutes: breakLength)
            } label: {
                Label("Start focus", systemImage: "timer")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Color.appBackground)
            }
        }
        .padding()
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var runningControls: some View {
        HStack(spacing: 32) {
            Button("Reset", systemImage: "arrow.counterclockwise") {
                focusTimer.reset()
            }

            Button(focusTimer.isPaused ? "Resume" : "Pause",
                   systemImage: focusTimer.isPaused ? "play.fill" : "pause.fill") {
                focusTimer.isPaused ? focusTimer.resume() : focusTimer.pause()
            }
            .font(.title2)
        }
        .foregroundStyle(Color.accentColor)
    }
}
