//
//  MainTabView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 3/11/2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TaskListView()
            }
            .tabItem { Label("Tasks", systemImage: "checklist") }

            NavigationStack {
                ContentUnavailableView("Focus", systemImage: "timer",
                                       description: Text("Focus sessions are coming soon."))
                    .navigationTitle("Focus")
            }
            .tabItem { Label("Focus", systemImage: "timer") }

            NavigationStack {
                ContentUnavailableView("Statistics", systemImage: "chart.bar",
                                       description: Text("Your carrot harvest will appear here."))
                    .navigationTitle("Statistics")
            }
            .tabItem { Label("Statistics", systemImage: "chart.bar") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview("Light") {
    MainTabView()
        .environmentObject(TaskStore.preview)
}

#Preview("Dark, large text") {
    MainTabView()
        .environmentObject(TaskStore.preview)
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility2)
}
