//
//  Statistics.swift
//  Bun and Done
//
//  Created by Clare Ahn on 10/11/2026.
//

import Foundation
import SwiftData

// One row in the "Carrots by task" list
struct TaskCarrotCount: Identifiable {
    let id: UUID
    let title: String
    let count: Int
}

extension TaskStore {
    // Start of each of the last 7 days, oldest first, ending today
    var lastSevenDays: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<7).reversed().compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: today)
        }
    }

    var weekSessions: [FocusSession] {
        guard let start = lastSevenDays.first else { return [] }
        return allSessions.filter { $0.completedAt >= start }
    }

    var weekFocusMinutes: Int {
        weekSessions.reduce(0) { $0 + $1.durationMinutes }
    }

    func carrots(on day: Date) -> Int {
        allSessions.filter { Calendar.current.isDate($0.completedAt, inSameDayAs: day) }.count
    }

    // Days in a row with at least one session.
    // If there's nothing today yet, count from yesterday so the streak isn't lost mid-day.
    var streakDays: Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: Date())

        if carrots(on: day) == 0 {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while carrots(on: day) > 0 {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }

    // This week's carrots grouped by task, most carrots first
    var carrotsByTask: [TaskCarrotCount] {
        var counts: [UUID: TaskCarrotCount] = [:]

        for session in weekSessions {
            guard let task = session.task, task.modelContext != nil else { continue }
            let current = counts[task.id]?.count ?? 0
            counts[task.id] = TaskCarrotCount(id: task.id, title: task.title, count: current + 1)
        }

        return counts.values.sorted { $0.count > $1.count }
    }
}
