//
//  Bun_and_DoneApp.swift
//  Bun and Done
//
//  Created by Clare Ahn on 15/10/2026.
//

import SwiftData
import SwiftUI

@main
struct Bun_and_DoneApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var taskStore: TaskStore
 
    init() {
        do {
            let container = try ModelContainer(for: TaskItem.self, AppSettings.self)
            modelContainer = container
            _taskStore = StateObject(
                wrappedValue: TaskStore(modelContext: container.mainContext)
            )
        } catch {
            fatalError("Failed to create the data store: \(error)")
        }
    }
 
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(taskStore)
        }
        .modelContainer(modelContainer)
    }
}
