//
//  TaskItem.swift
//  Bun and Done
//
//  Created by Clare Ahn on 20/10/2026.
//

import Foundation
import SwiftData
// Priority levels. String raw values + Codable so SwiftData can save it
// CaseIterable lets the UI loop over all cases. Identifiable lets ForEach use it
enum Priority: String, CaseIterable, Identifiable, Codable {
    case low
    case medium
    case high
    
    // Identifiable needs an id. The raw string ("low", "medium", "high") is unique per case
    var id: String { rawValue }
    // "low" -> "Low" for display
    var title: String {
        rawValue.capitalized
    }
}

@Model
// @Model turns this class into a SwiftData model. Every stored property is saved to the database
final class TaskItem {
    // Each task gets a unique UUID. .unique stops two records having the same id
    @Attribute(.unique) var id: UUID
    // Default delete rule (nullify): deleting a task keeps its sessions, but sets their task to nil
    @Relationship(inverse: \FocusSession.task) var focusSessions: [FocusSession] = []
    var title: String
    // Tags are stored as a plain list of strings (simpler than a separate Tag model)
    var tags: [String]
    var priority: Priority
    var dueDate: Date?
    var isCompleted: Bool
    // Used to sort the task list in creation order
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        tags: [String] = [],
        priority: Priority = .medium,
        dueDate: Date? = nil,
        isCompleted: Bool = false
    ) {
        // Default values let you create a task with just a title. createdAt is always set to now
        self.id = id
        self.title = title
        self.tags = tags
        self.priority = priority
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }

    // Whole days from today to the due date. Both dates are cut to midnight first,
    // so 11pm vs 9am doesn't change the count. nil if there's no due date. Negative = overdue
    var daysLeft: Int? {
        guard let dueDate else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let due = Calendar.current.startOfDay(for: dueDate)
        return Calendar.current.dateComponents([.day], from: today, to: due).day
    }
    
    // Text for the D-day badge: "D-3", "Today", "Overdue" or "No date"
    var dueLabel: String {
        guard let daysLeft else { return "No date" }
        if daysLeft < 0 { return "Overdue" }
        if daysLeft == 0 { return "Today" }
        return "D-\(daysLeft)"
    }
    
    // The same info in words for VoiceOver
    var dueAccessibilityLabel: String {
        guard let daysLeft else { return "No due date" }
        if daysLeft < 0 { return "Overdue" }
        if daysLeft == 0 { return "Due today" }
        return "Due in \(daysLeft) days"
    }
    // Adds up the minutes of every focus session linked to this task
    // reduce starts at 0 and adds each session's durationMinutes
    var totalFocusMinutes: Int {
        focusSessions.reduce(0) { $0 + $1.durationMinutes }
    }

    // Formats the minutes as "45m", "2h" or "1h 30m".
    var focusTimeLabel: String {
        let hours = totalFocusMinutes / 60
        let minutes = totalFocusMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }
}
