//
//  FocusTimer.swift
//  Bun and Done
//
//  Created by Clare Ahn on 5/11/2026.
//

import Foundation
import Combine

@MainActor
final class FocusTimer: ObservableObject {
    enum Phase { case idle, focusing, breakReady, onBreak }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var secondsRemaining = 0
    @Published private(set) var isPaused = false

    var onFocusCompleted: ((Int) -> Void)?

    private var totalSeconds = 0
    private var endDate: Date?
    private var focusMinutes = 25
    private var breakMinutes = 5
    private var ticker: AnyCancellable?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - Double(secondsRemaining) / Double(totalSeconds)
    }

    var timeText: String {
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    func startFocus(focusMinutes: Int, breakMinutes: Int) {
        self.focusMinutes = focusMinutes
        self.breakMinutes = breakMinutes
        begin(.focusing, minutes: focusMinutes)
    }

    func pause() {
        guard phase == .focusing || phase == .onBreak, isPaused == false else { return }
        isPaused = true
        endDate = nil
        ticker = nil
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        endDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        startTicking()
    }

    func reset() {
        ticker = nil
        endDate = nil
        isPaused = false
        phase = .idle
        secondsRemaining = 0
        totalSeconds = 0
    }
    
    func startBreak() {
        guard phase == .breakReady else { return }
        begin(.onBreak, minutes: breakMinutes)
    }

    private func begin(_ newPhase: Phase, minutes: Int) {
        phase = newPhase
        isPaused = false
        totalSeconds = minutes * 60
        secondsRemaining = totalSeconds
        endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        startTicking()
    }

    private func startTicking() {
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard let endDate else { return }
        secondsRemaining = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
        if secondsRemaining == 0 { finishPhase() }
    }

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
