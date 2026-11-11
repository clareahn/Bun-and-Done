//
//  TaskListView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 15/10/2026.
//
import SwiftUI
// Tasks tab: header with filter chips, then Due soon / No due date / Completed (collapsible) sections, floating + button
struct TaskListView: View {
    @EnvironmentObject private var taskStore: TaskStore
    // @State = local state for this screen only
    @State private var isShowingCompleted = false // is the Completed list open?
    @State private var isShowingAddTask = false // is the New Task pop-up open?

    var body: some View {
        List {
            Section {
                headerSection
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            // Empty state message when there are no open tasks (for the current filter)
            if taskStore.dueSoonTasks.isEmpty && taskStore.noDueDateTasks.isEmpty {
                Section {
                    Text("No open tasks here. Tap + to add one")
                        .foregroundStyle(Color.secondaryText)
                        .listRowBackground(Color.cardBackground)
                }
            }
            
            if taskStore.dueSoonTasks.isEmpty == false {
                // Each section only appears if it has tasks
                Section("Due soon") {
                    ForEach(taskStore.dueSoonTasks) { task in
                        taskLink(task)
                            .listRowBackground(Color.cardBackground)
                    }
                    .onDelete { offsets in // turns on swipe-to-delete
                        taskStore.deleteTasksFromList(at: offsets, from: taskStore.dueSoonTasks)
                    }
                }
            }

            if taskStore.noDueDateTasks.isEmpty == false {
                Section("No due date") {
                    ForEach(taskStore.noDueDateTasks) { task in
                        taskLink(task)
                            .listRowBackground(Color.cardBackground)
                    }
                    .onDelete { offsets in
                        taskStore.deleteTasksFromList(at: offsets, from: taskStore.noDueDateTasks)
                    }
                }
            }
            // Completed rows are only drawn when the section is expanded
            if taskStore.completedTasks.isEmpty == false {
                Section {
                    if isShowingCompleted {
                        ForEach(taskStore.completedTasks) { task in
                            taskLink(task)
                                .listRowBackground(Color.cardBackground)
                        }
                        .onDelete { offsets in
                            taskStore.deleteTasksFromList(at: offsets, from: taskStore.completedTasks)
                        }
                    }
                } header: {
                    completedHeader
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Tasks")
        // floating + button
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
        // Add Task opens as a sheet with its own NavigationStack
        .sheet(isPresented: $isShowingAddTask) {
            NavigationStack {
                AddTaskView()
            }
            .environmentObject(taskStore)
        }
    }
        
    // Details screen
    // Tapping the row opens TaskDetailView
    private func taskLink(_ task: TaskItem) -> some View {
        NavigationLink {
            TaskDetailView(task:task)
        } label: {
            TaskRowView(task: task) {
                taskStore.toggleCompleted(task) // block is passed to TaskRowView and runs when its circle button is tapped (marks done)
            }
        }
    }
    private var addButton: some View {
        Button {
            isShowingAddTask = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .padding(18)
                .background(Color.chipBackground, in: Circle())
                .foregroundStyle(Color.accentColor)
        }
        .padding()
                .accessibilityLabel("Add task")
    }
    // Today's date + open task count, then a horizontal row of filter chips
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(Date().formatted(.dateTime.weekday(.wide).day().month(.wide))) · \(taskStore.openCount) open")
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterButton(title: "All", priority: nil)
                    ForEach(Priority.allCases) { priority in filterButton(title: priority.title, priority: priority)
                    }
                }
            }
        }
    }
    // One chip. Tapping it sets selectedPriority in the store, which re-filters the sections
    private func filterButton(title: String, priority: Priority?) -> some View {
        let isSelected = taskStore.selectedPriority == priority

        return Button(title) {
            taskStore.selectedPriority = priority
        }
        .buttonStyle(.plain)
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isSelected ? Color.primaryText : Color.cardBackground, in: Capsule())
        .foregroundStyle(isSelected ? Color.appBackground : Color.primaryText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    // Tappable header that expands/collapses the Completed section with an animation
    private var completedHeader: some View {
        Button {
            withAnimation { isShowingCompleted.toggle() }
        } label: {
            HStack {
                Text("Completed (\(taskStore.completedTasks.count))")
                Spacer()
                Image(systemName: isShowingCompleted ? "chevron.up" : "chevron.down")
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.secondaryText)
    }
}

#Preview("Light") {
    NavigationStack {
        TaskListView()
    }
    .environmentObject(TaskStore.preview)
}

#Preview("Dark, large text") {
    NavigationStack {
        TaskListView()
    }
    .environmentObject(TaskStore.preview)
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility2)
}

#Preview("Landscape", traits: .landscapeLeft) {
    NavigationStack {
        TaskListView()
    }
    .environmentObject(TaskStore.preview)
}
