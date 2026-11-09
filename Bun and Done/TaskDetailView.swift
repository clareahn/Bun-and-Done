//
//  TaskDetailView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 20/10/2026.
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let task: TaskItem

    @State private var isShowingDeleteAlert = false
    @State private var isShowingEdit = false

    var body: some View {
        // After a delete the task has no modelContext, so stop reading it
        if task.modelContext != nil {
            details
        }
    }

    private var details: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(task.title)
                    .font(.title.bold())
                    .foregroundStyle(Color.primaryText)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        tagsAndPriority
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        tagsAndPriority
                    }
                }

                // Cards sit side by side, but stack at accessibility text sizes
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 12) {
                        dueCard
                        focusTimeCard
                    }
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        dueCard
                        focusTimeCard
                    }
                }

                Button {
                    taskStore.toggleCompleted(task)
                } label: {
                    Label(task.isCompleted ? "Mark as not done" : "Mark task complete",
                          systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Color.appBackground)
                }
                
                focusHistory

                Button(role: .destructive) {
                    isShowingDeleteAlert = true
                } label: {
                    Text("Delete task")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isShowingEdit = true }
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            NavigationStack {
                AddTaskView(taskToEdit: task)
            }
            .environmentObject(taskStore)
        }
        .alert("Delete this task?", isPresented: $isShowingDeleteAlert) {
            Button("Delete", role: .destructive) { deleteTask() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This can't be undone.")
        }
    }

    // Pieces of the screen
    @ViewBuilder
    private var tagsAndPriority: some View {
        ForEach(task.tags, id: \.self) { tag in
            Text(tag)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.chipBackground, in: RoundedRectangle(cornerRadius: 4))
        }
        
        HStack(spacing: 4) {
            Image(systemName: "flag.fill")
            Text(task.priority.title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(task.priority == .high ? Color.accentColor : Color.secondaryText)
        .accessibilityLabel("\(task.priority.title) priority")
        .fixedSize()
    }

    private var dueCard: some View {
        infoCard(
            heading: "Due",
            value: task.isCompleted ? "Done" : task.dueLabel,
            detail: task.dueDate?.formatted(.dateTime.weekday(.abbreviated).day().month()) ?? "No due date",
            valueColour: task.isCompleted ? Color.successGreen : Color.accentColor
        )
        .accessibilityElement(children: .combine)
    }

    private var focusTimeCard: some View {
        infoCard(
            heading: "Time focused",
            value: task.focusTimeLabel,
            detail: "\(task.focusSessions.count) carrots grown",
            valueColour: Color.primaryText
        )
        .accessibilityElement(children: .combine)
    }

    private func infoCard(heading: String, value: String, detail: String, valueColour: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(heading)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondaryText)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(valueColour)
            Text(detail)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var focusHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Focus history")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondaryText)
                .textCase(.uppercase)

            if task.focusSessions.isEmpty {
                Text("No focus sessions yet.")
                    .foregroundStyle(Color.secondaryText)
            } else {
                ForEach(task.focusSessions.sorted { $0.completedAt > $1.completedAt }) { session in
                    HStack {
                        Text(session.completedAt.formatted(date: .abbreviated, time: .shortened))
                        Spacer()
                        Text("\(session.durationMinutes) min")
                            .foregroundStyle(Color.secondaryText)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    // Actions

    private func deleteTask() {
        taskStore.deleteTask(task)
        dismiss()
    }
}

#Preview("Light") {
    let store = TaskStore.preview
    return NavigationStack {
        TaskDetailView(task: store.allTasks[1])
    }
    .environmentObject(store)
}

#Preview("Dark, large text") {
    let store = TaskStore.preview
    return NavigationStack {
        TaskDetailView(task: store.allTasks[1])
    }
    .environmentObject(store)
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility2)
}
