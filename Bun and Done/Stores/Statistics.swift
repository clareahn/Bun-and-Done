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
// Statistics calculations, added to TaskStore in a separate file to keep it tidy.
// They read allSessions, so the Statistics screen updates whenever a session is saved.
extension TaskStore {
    // Start of each of the last 7 days, oldest first, ending today
    var lastSevenDays: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<7).reversed().compactMap {// (0..<7).reversed() = 6, 5, .. 0 days ago, so the oldest day comes first
            // compactMap skips any date that couldn't be calculated (nil).
            Calendar.current.date(byAdding: .day, value: -$0, to: today)
        }
    }
    // Sessions completed since the start of the first of those 7 days.
    var weekSessions: [FocusSession] {
        guard let start = lastSevenDays.first else { return [] }
        return allSessions.filter { $0.completedAt >= start }
    }
    // Total focus minutes over the last 7 days.
    var weekFocusMinutes: Int {
        weekSessions.reduce(0) { $0 + $1.durationMinutes }
    }
    // Number of sessions on one day (one carrot per session).
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
        // Go back one day at a time for as long as each day has at least one session.
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
        // Dictionary keyed by task id to count sessions per task.
        // Skips sessions with no task, or whose task was deleted (modelContext == nil).
        for session in weekSessions {
            guard let task = session.task, task.modelContext != nil else { continue }
            let current = counts[task.id]?.count ?? 0
            counts[task.id] = TaskCarrotCount(id: task.id, title: task.title, count: current + 1)
        }

        return counts.values.sorted { $0.count > $1.count }
    }
}
