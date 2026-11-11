//
//  FocusView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 9/11/2026.
//

import SwiftUI
import SwiftData
// Focus tab. Shows the ring and time, plus different controls for each timer phase:
// setup (idle), Start break / Skip (breakReady), Pause / Reset (running).
// It also connects the timer to saving sessions, notifications and sound (see the onChange blocks).
struct FocusView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var focusTimer: FocusTimer
    // Local picker values, loaded from Settings when the screen appears.
    @State private var focusLength = 25
    @State private var breakLength = 5
    // Task picked in "Working on". The finished session gets linked to it.
    @State private var selectedTask: TaskItem?

    private let focusOptions = [15, 25, 45, 60]
    private let breakOptions = [5, 10, 15]
    
    // sound
    @EnvironmentObject private var soundPlayer: SoundPlayer
    @State private var isShowingSounds = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                FocusRingView(progress: focusTimer.progress,
                              isBreak: focusTimer.phase == .onBreak)
                    .frame(width: 240, height: 240)
                // Idle: show the chosen length. Otherwise: the live countdown.
                Text(focusTimer.phase == .idle ? "\(focusLength):00" : focusTimer.timeText)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    // stops the text jiggling as the numbers change.
                    .monospacedDigit()
                    .foregroundStyle(Color.primaryText)
                // Show different controls depending on the phase.
                if focusTimer.phase == .idle {
                    setupControls
                } else if focusTimer.phase == .breakReady {
                    currentTaskText
                    Button {
                        focusTimer.startBreak()
                    } label: {
                        Label("Start break", systemImage: "cup.and.saucer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.successGreen, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(Color.appBackground)
                    }
                    Button("Skip break") {
                        focusTimer.reset()
                    }
                    .foregroundStyle(Color.accentColor)
                } else {
                    currentTaskText
                    runningControls
                }
            }
            .padding()
            .frame(maxWidth: .infinity) // Keeps content full width when the controls change
        }
        .background(Color.appBackground)
        .navigationTitle("Focus")
        
        // sound
        // Music button opens the sound sheet. The icon changes while a sound is playing.
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingSounds = true
                } label: {
                    Image(systemName: soundPlayer.isPlaying ? "speaker.wave.2.fill" : "music.note")
                }
                .accessibilityLabel("Focus sounds")
            }
        }
        .sheet(isPresented: $isShowingSounds) {
            NavigationStack {
                SoundPlayerView()
            }
            .environmentObject(soundPlayer)
            // Half-height sheet that can be dragged up to full height.
            .presentationDetents([.medium, .large])
        }
        
        .onAppear {
            // Load the default lengths from Settings, and clear the picked task if it's gone.
            focusLength = taskStore.settings.focusLength
            breakLength = taskStore.settings.breakLength
            clearSelectedTaskIfNeeded()
        }
        // Whenever the task list changes, check the picked task is still valid.
        .onReceive(taskStore.$allTasks) { _ in
            clearSelectedTaskIfNeeded()
        }
        // Runs every time the timer's phase changes
        .onChange(of: focusTimer.phase) { _, newPhase in
            // A focus session reached 00:00, so save it
            if newPhase == .breakReady {
                let task = selectedTask?.modelContext != nil ? selectedTask : nil
                taskStore.addFocusSession(minutes: focusLength, task: task)
            }

            if newPhase == .focusing {
                scheduleFocusNotification(in: focusLength * 60)
            } else {
                // Stop background sound whenever a focus session finishes or is reset
                soundPlayer.stop()
            }

            // Only cancel when the user resets; if focus finished on its own, let the notification fire
            if newPhase == .idle {
                FocusNotifications.cancelFocusEnd()
            }
        }
        
        .onChange(of: focusTimer.isPaused) { _, isPaused in
            guard focusTimer.phase == .focusing else { return }

            if isPaused {
                FocusNotifications.cancelFocusEnd()
            } else {
                scheduleFocusNotification(in: focusTimer.secondsRemaining)
            }
        }
    }
    // Shown when idle: task picker, focus/break length pickers, Start button
    private var setupControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Working on").font(.subheadline.weight(.semibold))
                Spacer()
                Picker("Working on", selection: $selectedTask) {
                    // .tag() tells the picker what to save into selectedTask when you pick an option (task)
                    // "No task" saves nil and picking a task sets selectedTask to that task.
                    Text("No task").tag(nil as TaskItem?)
                    ForEach(taskStore.openTasks) { task in
                        Text(task.title).tag(task as TaskItem?)
                    }
                }
                .pickerStyle(.menu)
            }
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
    // @ViewBuilder lets view property use an "if" with no "else"
    // If a task is picked, show "Working on: ...". If not, show nothing
    @ViewBuilder
    private var currentTaskText: some View { // view property
        if let task = selectedTask, task.modelContext != nil {
            Text("\(focusTimer.phase == .onBreak ? "Taking a break from" : "Working on"): \(task.title)")
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    // Reset (Skip during a break) and Pause/Resume
    private var runningControls: some View {
        HStack(spacing: 32) {
            Button(focusTimer.phase == .onBreak ? "Skip" : "Reset",
                   systemImage: focusTimer.phase == .onBreak ? "forward.end.fill" : "arrow.counterclockwise") {
                focusTimer.reset()
            }

            Button(focusTimer.isPaused ? "Resume" : "Pause",
                   systemImage: focusTimer.isPaused ? "play.fill" : "pause.fill") {
                focusTimer.isPaused ? focusTimer.resume() : focusTimer.pause()
            }
        }
        .font(.title2)
        .foregroundStyle(Color.accentColor)
    }
    // Only schedule if notification preference is turned on in Settings
    private func scheduleFocusNotification(in seconds: Int) {
        guard taskStore.settings.notifySessionEnds else { return }
        FocusNotifications.scheduleFocusEnd(in: seconds)
    }
    
    // Reset the dropdown if the selected task was deleted or completed
    private func clearSelectedTaskIfNeeded() {
        if let task = selectedTask, task.modelContext == nil || task.isCompleted {
            selectedTask = nil
        }
    }
}

#Preview("Light") {
    NavigationStack {
        FocusView()
    }
    .environmentObject(TaskStore.preview)
    .environmentObject(FocusTimer())
    .environmentObject(SoundPlayer())

}

#Preview("Dark, large text") {
    NavigationStack {
        FocusView()
    }
    .environmentObject(TaskStore.preview)
    .environmentObject(FocusTimer())
    .environmentObject(SoundPlayer())
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility2)
}

#Preview("Landscape", traits: .landscapeLeft) {
    NavigationStack {
        FocusView()
    }
    .environmentObject(TaskStore.preview)
    .environmentObject(FocusTimer())
    .environmentObject(SoundPlayer())
}
