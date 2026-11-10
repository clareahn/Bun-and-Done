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
                FocusView()
            }
            .tabItem { Label("Focus", systemImage: "timer") }

            NavigationStack {
                StatisticsView()
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

#Preview("Landscape", traits: .landscapeLeft) {
    MainTabView()
        .environmentObject(TaskStore.preview)
}
