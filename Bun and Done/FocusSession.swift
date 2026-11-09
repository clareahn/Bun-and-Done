//
//  FocusSession.swift
//  Bun and Done
//
//  Created by Clare Ahn on 9/11/2026.
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    var completedAt: Date
    var durationMinutes: Int
    var task: TaskItem?

    init(completedAt: Date = Date(), durationMinutes: Int) {
        self.completedAt = completedAt
        self.durationMinutes = durationMinutes
    }
}
