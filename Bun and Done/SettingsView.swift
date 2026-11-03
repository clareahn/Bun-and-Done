//
//  SettingsView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 3/11/2026.
//
//
//  SettingsView.swift
//  Bun and Done
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var taskStore: TaskStore

    // Local copies of the saved settings, loaded when the screen appears
    @State private var focusLength = 25
    @State private var breakLength = 5
    @State private var notifySessionEnds = true
    @State private var deadlineReminders = true
    @State private var reminderDaysBefore = 1

    private let focusOptions = [15, 25, 45, 60]
    private let breakOptions = [5, 10, 15]
    private let reminderOptions = [0, 1, 2]

    var body: some View {
        Form {
            Section("Focus timer") {
                Picker("Focus length", selection: $focusLength) {
                    ForEach(focusOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }

                Picker("Break length", selection: $breakLength) {
                    ForEach(breakOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
            }
            .listRowBackground(Color.cardBackground)

            Section("Notifications") {
                Toggle("Session ends", isOn: $notifySessionEnds)
                    .tint(Color.successGreen)

                Toggle("Deadline reminders", isOn: $deadlineReminders)
                    .tint(Color.successGreen)

                if deadlineReminders {
                    Picker("Remind me", selection: $reminderDaysBefore) {
                        ForEach(reminderOptions, id: \.self) { days in
                            Text(reminderText(days)).tag(days)
                        }
                    }
                }
            }
            .listRowBackground(Color.cardBackground)
        }
        .pickerStyle(.navigationLink)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("Settings")
        .onAppear(perform: loadSettings)
        .onChange(of: focusLength) { saveSettings() }
        .onChange(of: breakLength) { saveSettings() }
        .onChange(of: notifySessionEnds) { saveSettings() }
        .onChange(of: deadlineReminders) { saveSettings() }
        .onChange(of: reminderDaysBefore) { saveSettings() }
    }

    // MARK: - Helper functions

    private func loadSettings() {
        let settings = taskStore.settings
        focusLength = settings.focusLength
        breakLength = settings.breakLength
        notifySessionEnds = settings.notifySessionEnds
        deadlineReminders = settings.deadlineReminders
        reminderDaysBefore = settings.reminderDaysBefore
    }

    private func saveSettings() {
        taskStore.updateSettings(
            focusLength: focusLength,
            breakLength: breakLength,
            notifySessionEnds: notifySessionEnds,
            deadlineReminders: deadlineReminders,
            reminderDaysBefore: reminderDaysBefore
        )
    }

    private func reminderText(_ days: Int) -> String {
        switch days {
        case 0: return "On the day"
        case 1: return "1 day before"
        default: return "\(days) days before"
        }
    }
}

#Preview("Light") {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(TaskStore.preview)
}

#Preview("Dark, large text") {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(TaskStore.preview)
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility2)
}
