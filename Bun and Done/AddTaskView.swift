//
//  AddTaskView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 20/10/2026.
//

import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss

    // Task details entered by the user
    @State private var title = ""
    @State private var priority: Priority = .medium
    @State private var selectedTags: [String] = []
    @State private var newTagText = ""
    @State private var extraTags: [String] = []
    @State private var hasDueDate = true
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    // Alert variables
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isShowingAlert = false

    var taskToEdit: TaskItem? = nil
    
    // Default tags plus any new ones made on this screen
    private var tagOptions: [String] {
        taskStore.allTags + extraTags
    }

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title, prompt: Text("e.g. FIT3178 Assignment 2"))
            }
            .listRowBackground(Color.cardBackground)

            Section("Priority") {
                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.cardBackground)

            Section("Tags") {
                ForEach(tagOptions, id: \.self) { tag in
                    Button {
                        toggleTag(tag)
                    } label: {
                        HStack {
                            Text(tag)
                                .foregroundStyle(Color.primaryText)
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        // Makes the whole row tappable
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedTags.contains(tag) ? .isSelected : [])
                }

                HStack {
                    TextField("New tag", text: $newTagText)
                        .onSubmit(addNewTag)
                    Button("Add", action: addNewTag)
                }
            }
            .listRowBackground(Color.cardBackground)

            Section {
                Toggle("Due date", isOn: $hasDueDate)
                    .tint(Color.successGreen)

                if hasDueDate {
                    DatePicker("Date", selection: $dueDate, in: min(dueDate, Date())..., displayedComponents: .date)
                }
            } header: {
                Text("Deadline")
            } footer: {
                if hasDueDate {
                    Text("Shows as \(daysLabel) on your task list.")
                }
            }
            .listRowBackground(Color.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle(taskToEdit == nil ? "New Task" : "Edit Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(taskToEdit == nil ? "Add" : "Save") { createTask() }
            }
        }
        .alert(alertTitle, isPresented: $isShowingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear(perform: loadTaskToEdit)
    }

    // Helper functions
    private var daysLabel: String {
        let today = Calendar.current.startOfDay(for: Date())
        let due = Calendar.current.startOfDay(for: dueDate)
        let days = Calendar.current.dateComponents([.day], from: today, to: due).day ?? 0
        return days == 0 ? "Today" : "D-\(days)"
    }

    private func toggleTag(_ tag: String) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    private func addNewTag() {
        let trimmedTag = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedTag.isEmpty == false else {
            displayMessage(title: "Missing tag name", message: "Please type a name for the new tag.")
            return
        }

        guard tagOptions.contains(where: { $0.lowercased() == trimmedTag.lowercased() }) == false else {
            displayMessage(title: "Tag already exists", message: "\(trimmedTag) is already in your tag list.")
            return
        }

        extraTags.append(trimmedTag)
        selectedTags.append(trimmedTag)
        newTagText = ""
    }

    private func createTask() {
        let result: TaskStore.TaskCreationResult
        if let task = taskToEdit {
            result = taskStore.updateTask(task, title: title, tags: selectedTags, priority: priority, dueDate: hasDueDate ? dueDate : nil)
        } else {
            result = taskStore.addTask(title: title, tags: selectedTags,priority: priority, dueDate: hasDueDate ? dueDate : nil)
        }

        switch result {
        case .success:
            dismiss()
        case .missingTitle:
            displayMessage(title: "Missing title", message: "Please enter a title for your task.")
        case .duplicateTitle:
            displayMessage(title: "Task already exists", message: "You already have an open task with this title.")
        }
    }

    private func displayMessage(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        isShowingAlert = true
    }
    
    private func loadTaskToEdit() {
        guard let task = taskToEdit else { return }
        title = task.title
        priority = task.priority
        selectedTags = task.tags
        hasDueDate = task.dueDate != nil
        if let existingDate = task.dueDate {
            dueDate = existingDate
        }
    }
}

#Preview("Light") {
    NavigationStack {
        AddTaskView()
    }
    .environmentObject(TaskStore.preview)
}

#Preview("Dark, large text") {
    NavigationStack {
        AddTaskView()
    }
    .environmentObject(TaskStore.preview)
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility2)
}
