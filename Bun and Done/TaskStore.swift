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
    
    @Published private(set) var allTasks: [TaskItem] = []
    @Published var selectedTag = "All"

    let filterTags = ["All", "Study", "Work", "Chores"]
    private let defaultTags = ["Study", "University", "Work", "Chores", "Personal"]

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadDefaultTasks()
        saveAndRefresh()
    }

    // Lists used by the task screen

    private var filteredTasks: [TaskItem] {
        guard selectedTag != "All" else { return allTasks }
        return allTasks.filter { $0.tags.contains(selectedTag) }
    }

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
    
    // Adding, completing and deleting
    func addTask(title: String, tags: [String], priority: Priority, dueDate: Date?) -> TaskCreationResult {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
 
        guard trimmedTitle.isEmpty == false else {
            return .missingTitle
        }
 
        guard allTasks.contains(where: {
            $0.isCompleted == false &&
            $0.title.localizedCaseInsensitiveCompare(trimmedTitle) == .orderedSame
        }) == false else {
            return .duplicateTitle
        }
 
        modelContext.insert(TaskItem(title: trimmedTitle, tags: tags, priority: priority, dueDate: dueDate))
        saveAndRefresh()
        return .success
    }

    func toggleCompleted(_ task: TaskItem) {
        task.isCompleted.toggle()
        saveAndRefresh()
    }

    
    func deleteTasksFromList(at offsets: IndexSet, from displayedTasks: [TaskItem]) {
        let tasksToDelete = offsets.map { displayedTasks[$0] }

        for task in tasksToDelete {
            modelContext.delete(task)
        }

        saveAndRefresh()
    }
    
    func deleteTask(_ task: TaskItem) {
        modelContext.delete(task)
        saveAndRefresh()
    }

    // Database helpers

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

    private func saveAndRefresh() {
        do {
            try modelContext.save()
            allTasks = fetchAllTasks()
        } catch {
            print("Failed to save task changes: \(error)")
        }
    }
}

// Preview helper

extension TaskStore {
    static let previewContainer: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: TaskItem.self, configurations: configuration)
    }()

    static var preview: TaskStore {
        TaskStore(modelContext: previewContainer.mainContext)
    }
}
