//
//  TaskItem.swift
//  Bun and Done
//
//  Created by Clare Ahn on 20/10/2026.
//

import Foundation
import SwiftData

enum Priority: String, CaseIterable, Identifiable, Codable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var tags: [String]
    var priority: Priority
    var dueDate: Date?
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        tags: [String] = [],
        priority: Priority = .medium,
        dueDate: Date? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.tags = tags
        self.priority = priority
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }

    var daysLeft: Int? {
        guard let dueDate else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let due = Calendar.current.startOfDay(for: dueDate)
        return Calendar.current.dateComponents([.day], from: today, to: due).day
    }

    var dueLabel: String {
        guard let daysLeft else { return "No date" }
        if daysLeft < 0 { return "Overdue" }
        if daysLeft == 0 { return "Today" }
        return "D-\(daysLeft)"
    }

    var dueAccessibilityLabel: String {
        guard let daysLeft else { return "No due date" }
        if daysLeft < 0 { return "Overdue" }
        if daysLeft == 0 { return "Due today" }
        return "Due in \(daysLeft) days"
    }
}
