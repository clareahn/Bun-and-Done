//
//  FocusSession.swift
//  Bun and Done
//
//  Created by Clare Ahn on 9/11/2026.
//

import Foundation
import SwiftData

@Model
// One completed focus session (= one carrot). Saved when the timer reaches 00:00
final class FocusSession {
    var completedAt: Date
    var durationMinutes: Int
    // Which task session is for. nil if "No task" was picked, or if the task was deleted later
    // The other side of TaskItem.focusSessions
    var task: TaskItem?

    init(completedAt: Date = Date(), durationMinutes: Int) {
        self.completedAt = completedAt
        self.durationMinutes = durationMinutes
    }
}
