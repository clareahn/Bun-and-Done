//
//  TaskStore.swift
//  Bun and Done
//
//  Created by Clare Ahn on 20/10/2026.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class TaskStore: ObservableObject {
    enum TaskCreationResult {
         case success
         case missingTitle
         case duplicateTitle
     }
    // private(set) = views can read them, but only TaskStore can change them.
    @Published private(set) var allTasks: [TaskItem] = []
    @Published private(set) var allSessions: [FocusSession] = []
    // nil means all; otherwise only tasks with this priority are shown
    @Published var selectedPriority: Priority? = nil
    // Tags always offered on the Add Task screen.
    private let defaultTags = ["Study", "University", "Work", "Chores", "Personal"]
    // The SwiftData context: used to insert, delete, fetch and save.
    private let modelContext: ModelContext

    // On launch: add sample tasks if the database is empty, make sure a settings record exists,
    // then save and load everything into allTasks / allSessions
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadDefaultTasks()
        _ = fetchOrCreateSettings()
        saveAndRefresh()
    }
    // Always returns the single settings record (creates it if it's missing).
    var settings: AppSettings {
        fetchOrCreateSettings()
    }

    // Lists used by the task screen
    // Priority filter chip
    private var filteredTasks: [TaskItem] {
        guard let selectedPriority else { return allTasks }
        return allTasks.filter { $0.priority == selectedPriority }
    }
    // "Due soon" section: open tasks with a due date, earliest first
    // ?? .distantFuture is there to unwrap the optional; these tasks always have a date.
    var dueSoonTasks: [TaskItem] {
        filteredTasks
            .filter { $0.isCompleted == false && $0.dueDate != nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var noDueDateTasks: [TaskItem] {
        filteredTasks.filter { $0.isCompleted == false && $0.dueDate == nil }
    }

    var completedTasks: [TaskItem] {
        filteredTasks.filter { $0.isCompleted }
    }
    // Open count for header. e.g. 4 open
    var openCount: Int {
        allTasks.filter { $0.isCompleted == false }.count
    }
    
    // Default tags, plus any custom tags
    var allTags: [String] {
        var tags = defaultTags
        for task in allTasks {
            for tag in task.tags where tags.contains(tag) == false {
                tags.append(tag)
            }
        }
        return tags
    }
    // Used by the Focus screen's "Working on" picker and the previews
    var openTasks: [TaskItem] {
        allTasks.filter { $0.isCompleted == false }
    }
    
    // Adding, completing and deleting
    func addTask(title: String, tags: [String], priority: Priority, dueDate: Date?) -> TaskCreationResult {
        // Trim spaces
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        // Reject empty title
        guard trimmedTitle.isEmpty == false else {
            return .missingTitle
        }
        // Reject title matching an open task, ignores cases
        guard allTasks.contains(where: {
            $0.isCompleted == false &&
            $0.title.localizedCaseInsensitiveCompare(trimmedTitle) == .orderedSame
        }) == false else {
            return .duplicateTitle
        }
        // insert only stages the new task. saveAndRefresh() writes it to disk.
        modelContext.insert(TaskItem(title: trimmedTitle, tags: tags, priority: priority, dueDate: dueDate))
        saveAndRefresh()
        // Returns TaskCreationResult so AddTaskView shows correct alert
        return .success
    }
    // Toggle done / Not done. SwiftData notices changes and saves
    func toggleCompleted(_ task: TaskItem) {
        task.isCompleted.toggle()
        saveAndRefresh()
    }

    // Swipe to delete: called when the user swipes a row to delete it.
    // Swift tells us which row number was swiped (e.g. row 1), not which task.
    // Row numbers start again from 0 in every section
    func deleteTasksFromList(at offsets: IndexSet, from displayedTasks: [TaskItem]) {
        let tasksToDelete = offsets.map { displayedTasks[$0] }

        for task in tasksToDelete {
            modelContext.delete(task)
        }

        saveAndRefresh()
    }
    // Delete task in the task detail screen
    // "Delete task" button function
    func deleteTask(_ task: TaskItem) {
        modelContext.delete(task)
        saveAndRefresh()
    }
    // Called by SettingsView whenever a setting changes. Updates the single settings record and saves.
    func updateSettings(focusLength: Int, breakLength: Int, notifySessionEnds: Bool) {
            let settings = fetchOrCreateSettings()
            settings.focusLength = focusLength
            settings.breakLength = breakLength
            settings.notifySessionEnds = notifySessionEnds
            saveAndRefresh()
        }
    // Same validation as addTask, then overwrites the task's fields with the new values.
    func updateTask(_ task: TaskItem, title: String, tags: [String], priority: Priority, dueDate: Date?) -> TaskCreationResult {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedTitle.isEmpty == false else {
            return .missingTitle
        }

        // Same duplicate check as addTask, but ignore the task being edited
        guard allTasks.contains(where: {
            $0.id != task.id && // it's a different task from the one being edited
            $0.isCompleted == false && // and it's still open
            $0.title.localizedCaseInsensitiveCompare(trimmedTitle) == .orderedSame // and it has the same title
        }) == false else {
            return .duplicateTitle
        }

        task.title = trimmedTitle
        task.tags = tags
        task.priority = priority
        task.dueDate = dueDate
        saveAndRefresh()
        return .success
    }
    // Called when a focus session reaches 00:00. Creates a session record, links it to the chosen task
    func addFocusSession(minutes: Int, task: TaskItem?, completedAt: Date = Date()) {
        let session = FocusSession(completedAt: completedAt, durationMinutes: minutes)
        modelContext.insert(session)
        session.task = task   // set the link after inserting
        saveAndRefresh()
    }

    // Database helpers
    // Adds 5 sample tasks for the demo, but only if there are no tasks.
    private func loadDefaultTasks() {
        guard fetchAllTasks().isEmpty else { return }

        let calendar = Calendar.current
        let today = Date()

        let defaultTasks = [
            TaskItem(title: "Weekly grocery run", tags: ["Chores"], priority: .low,
                     dueDate: calendar.date(byAdding: .day, value: 1, to: today)),
            TaskItem(title: "FIT3178 C1 UI Design Proposal", tags: ["Study", "University"], priority: .high,
                     dueDate: calendar.date(byAdding: .day, value: 3, to: today)),
            TaskItem(title: "Read Week 8 lecture notes", tags: ["Study"], priority: .medium,
                     dueDate: calendar.date(byAdding: .day, value: 5, to: today)),
            TaskItem(title: "Update resume", tags: ["Personal"], priority: .medium),
            TaskItem(title: "Submit P6", tags: ["University"], priority: .high,
                     dueDate: calendar.date(byAdding: .day, value: -2, to: today), isCompleted: true)
        ]

        defaultTasks.forEach(modelContext.insert)
    }
    
    // Reads every task, oldest first. If the fetch fails it prints the error and returns an empty list w/ crashing
    private func fetchAllTasks() -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\TaskItem.createdAt)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }

    // Same for focus sessions, oldest first
    private func fetchAllSessions() -> [FocusSession] {
        let descriptor = FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\FocusSession.completedAt)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch focus sessions: \(error)")
            return []
        }
    }

    // Every change goes through here: save to disk, then re-read so the @Published arrays update
    private func saveAndRefresh() {
        do {
            try modelContext.save()
            allTasks = fetchAllTasks()
            allSessions = fetchAllSessions()
        } catch {
            print("Failed to save task changes: \(error)")
        }
    }
    
    // Settings is a single record. Fetch at most 1. If there isn't one (first launch) or the fetch failed, create one with the default values
    private func fetchOrCreateSettings() -> AppSettings {
            var descriptor = FetchDescriptor<AppSettings>()
            descriptor.fetchLimit = 1
     
            do {
                if let existingSettings = try modelContext.fetch(descriptor).first {
                    return existingSettings
                }
            } catch {
                print("Failed to fetch settings: \(error)")
            }
     
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            return newSettings
        }
}

// Preview helper

extension TaskStore {
    // In-memory database just for SwiftUI previews, so previews never touch real data
    static let previewContainer: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: TaskItem.self, AppSettings.self, FocusSession.self, configurations: configuration)
    }()

    static var preview: TaskStore {
        TaskStore(modelContext: previewContainer.mainContext)
    }
    
    // Preview store with some focus sessions spread over the past week
    static var statisticsPreview: TaskStore {
        let store = TaskStore(modelContext: previewContainer.mainContext)

        for (index, task) in store.openTasks.prefix(3).enumerated() {
            for daysAgo in 0..<(5 - index) {
                let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
                store.addFocusSession(minutes: 25, task: task, completedAt: date)
            }
        }
        return store
    }
}
