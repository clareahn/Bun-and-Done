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

    private let focusOptions = [15, 25, 45, 60]
    private let breakOptions = [5, 10, 15]

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
        .onChange(of: notifySessionEnds) { _, isOn in saveSettings()
            // Only ask for notification permission when the user turns this on
            if isOn {
                FocusNotifications.requestPermission()
            }
        }
    }

    // Helper functions

    private func loadSettings() {
        let settings = taskStore.settings
        focusLength = settings.focusLength
        breakLength = settings.breakLength
        notifySessionEnds = settings.notifySessionEnds
    }

    private func saveSettings() {
        taskStore.updateSettings(
            focusLength: focusLength,
            breakLength: breakLength,
            notifySessionEnds: notifySessionEnds
        )
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

#Preview("Landscape", traits: .landscapeLeft) {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(TaskStore.preview)
}
