//
//  FocusTimer.swift
//  Bun and Done
//
//  Created by Clare Ahn on 5/11/2026.
//

import Foundation
import Combine
// Runs the countdown. Knows nothing about SwiftData: FocusView watches `phase` and does the saving.
@MainActor
final class FocusTimer: ObservableObject {
    enum Phase { case idle, focusing, breakReady, onBreak } // idle: not started, focusing: focus countdown, breakReady: focus finished, wait for user to start break, onBreak: break countdown
    // @Published so FocusView redraws. private(set) so only the timer can change them.
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var secondsRemaining = 0
    @Published private(set) var isPaused = false

    var onFocusCompleted: ((Int) -> Void)?

    private var totalSeconds = 0 // Length of the current phase in seconds. Used for the progress ring
    private var endDate: Date? // The clock time the current cycle finishes (e.g. 10:25) nil when paused or idle
    private var focusMinutes = 25 // Saved when focus starts, so the break length is still known when the break begins
    private var breakMinutes = 5
    private var ticker: AnyCancellable? // The 1-second timer. Setting it to nil cancels it.

    // 0 at the start -> 1 at the end. Drives the ring and the carrot image.
    var progress: Double {
        // The guard avoids dividing by 0 when idle.
        guard totalSeconds > 0 else { return 0 }
        return 1 - Double(secondsRemaining) / Double(totalSeconds)
    }
    // e.g. 750 seconds -> "12:30"
    var timeText: String {
        // %02d pads to two digits
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }
    // Start button. Remembers both lengths, then begins the focus phase
    func startFocus(focusMinutes: Int, breakMinutes: Int) {
        self.focusMinutes = focusMinutes
        self.breakMinutes = breakMinutes
        begin(.focusing, minutes: focusMinutes)
    }
    // Only works while running and not already paused
    // Throws away endDate and stops ticking. secondsRemaining is kept so resume knows how long is left
    func pause() {
        guard phase == .focusing || phase == .onBreak, isPaused == false else { return }
        isPaused = true
        endDate = nil
        ticker = nil
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        // New finish time = now + time left, then start ticking again
        endDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        startTicking()
    }
    // Back to idle, clears everything. Used by Reset, Skip break, and when a break finishes
    func reset() {
        ticker = nil
        endDate = nil
        isPaused = false
        phase = .idle
        secondsRemaining = 0
        totalSeconds = 0
    }
    // Only allowed straight after a focus session finished -> breakReady.
    func startBreak() {
        guard phase == .breakReady else { return }
        begin(.onBreak, minutes: breakMinutes)
    }
    // Shared start logic: set the phase, work out the finish time (endDate), start ticking
    private func begin(_ newPhase: Phase, minutes: Int) {
        phase = newPhase
        isPaused = false
        totalSeconds = minutes * 60
        secondsRemaining = totalSeconds
        endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        startTicking()
    }
    // Calls tick() every second on the main thread
    private func startTicking() {
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            // [weak self] avoids a retain cycle (the timer keeping this object alive forever)
            .sink { [weak self] _ in self?.tick() }
    }
    // Every second: time left = endDate - now, so it's still correct after the app was in the background
    private func tick() {
        // nothing happens while paused (endDate is nil)
        guard let endDate else { return }
        secondsRemaining = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
        if secondsRemaining == 0 { finishPhase() }
    }
    // Focus ends -> breakReady (FocusView sees this and saves the session).
    // Break ends -> back to idle.
    private func finishPhase() {
        switch phase {
        case .focusing:
            ticker = nil
            endDate = nil
            phase = .breakReady
            onFocusCompleted?(focusMinutes)
        case .onBreak:
            reset()
        case .idle, .breakReady:
            break
        }
    }
}
