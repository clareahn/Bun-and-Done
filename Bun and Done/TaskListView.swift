//
//  TaskView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 15/10/2026.
//
import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var taskStore: TaskStore

    @State private var isShowingCompleted = false
    @State private var isShowingAddTask = false

    var body: some View {
        List {
            Section {
                headerSection
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if taskStore.dueSoonTasks.isEmpty && taskStore.noDueDateTasks.isEmpty {
                Section {
                    Text("No open tasks here. Tap + to add one")
                        .foregroundStyle(Color.secondaryText)
                        .listRowBackground(Color.cardBackground)
                }
            }

            if taskStore.dueSoonTasks.isEmpty == false {
                Section("Due soon") {
                    ForEach(taskStore.dueSoonTasks) { task in
                        taskLink(task)
                            .listRowBackground(Color.cardBackground)
                    }
                    .onDelete { offsets in
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
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
        .sheet(isPresented: $isShowingAddTask) {
            NavigationStack {
                AddTaskView()
            }
            .environmentObject(taskStore)
        }
    }
        
    // Details screen
    private func taskLink(_ task: TaskItem) -> some View {
        NavigationLink {
            TaskDetailView(task:task)
        } label: {
            TaskRowView(task: task) {
                taskStore.toggleCompleted(task)
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(Date().formatted(.dateTime.weekday(.wide).day().month(.wide))) · \(taskStore.openCount) open")
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(taskStore.filterTags, id: \.self) { tag in
                        filterButton(tag)
                    }
                }
            }
        }
    }

    private func filterButton(_ tag: String) -> some View {
        let isSelected = taskStore.selectedTag == tag

        return Button(tag) {
            taskStore.selectedTag = tag
        }
        .buttonStyle(.plain)
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isSelected ? Color.primaryText : Color.cardBackground, in: Capsule())
        .foregroundStyle(isSelected ? Color.appBackground : Color.primaryText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

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
