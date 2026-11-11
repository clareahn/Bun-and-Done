//
//  StatisticsView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 10/11/2026.
//

import SwiftUI
// Statistics tab. All the numbers come from Statistics.swift (TaskStore extension); this file only lays them out.
struct StatisticsView: View {
    @EnvironmentObject private var taskStore: TaskStore

    // Most carrots drawn in one day's column before showing "+x"
    private let maxCarrotsShown = 5

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(dateRangeText)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)

                harvestCard

                HStack(alignment: .top, spacing: 12) {
                    statCard(heading: "Focus time",
                             value: focusTimeText(taskStore.weekFocusMinutes),
                             detail: "last 7 days")
                    statCard(heading: "Streak",
                             value: "\(taskStore.streakDays) \(taskStore.streakDays == 1 ? "day" : "days")",
                             detail: "in a row")
                }

                carrotsByTaskSection
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Statistics")
    }

    // Harvest card with the weekly carrot chart

    private var harvestCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(taskStore.weekSessions.count) carrots")
                    .font(.title2.bold())
                    .foregroundStyle(Color.primaryText)
                Text("harvested in the last 7 days")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }

            HStack(alignment: .bottom) {
                ForEach(taskStore.lastSevenDays, id: \.self) { day in
                    dayColumn(for: day)
                        .frame(maxWidth: .infinity)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.large)       // Chart text stops growing past large
            .padding()
            .background(Color.chipBackground, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color.successGreen.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
    }

    // One column of the chart: stacked carrots with the day label underneath
    private func dayColumn(for day: Date) -> some View {
        let count = taskStore.carrots(on: day)
        let isToday = Calendar.current.isDateInToday(day)

        return VStack(spacing: 2) {
            if count > maxCarrotsShown {
                Text("+\(count - maxCarrotsShown)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
            }

            ForEach(0..<min(count, maxCarrotsShown), id: \.self) { _ in
                Text("🥕")
            }

            Text(isToday ? "Today" : day.formatted(.dateTime.weekday(.abbreviated)))
                .font(.caption2.weight(isToday ? .bold : .regular))
                .foregroundStyle(Color.primaryText)
                .padding(.top, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isToday ? "Today" : day.formatted(.dateTime.weekday(.wide))): \(count) carrots")
    }

    // Carrots by task

    private var carrotsByTaskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Carrots by task")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondaryText)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                if taskStore.carrotsByTask.isEmpty {
                    Text("Finish a focus session on a task to start growing carrots.")
                        .foregroundStyle(Color.secondaryText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(taskStore.carrotsByTask) { item in
                        HStack {
                            Text(item.title)
                                .foregroundStyle(Color.primaryText)
                            Spacer()
                            Text("\(item.count) 🥕")
                                .font(.headline)
                                .foregroundStyle(Color.primaryText)
                        }
                        .padding()
                        .accessibilityElement(children: .combine)

                        // Add a divider under every row except the last one
                        if item.id != taskStore.carrotsByTask.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // Helper functions

    private func statCard(heading: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(heading)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondaryText)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color.primaryText)
            Text(detail)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var dateRangeText: String {
        guard let first = taskStore.lastSevenDays.first,
              let last = taskStore.lastSevenDays.last else { return "" }
        return "\(first.formatted(.dateTime.day().month())) – \(last.formatted(.dateTime.day().month()))"
    }

    private func focusTimeText(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }
}

#Preview("Light") {
    NavigationStack {
        StatisticsView()
    }
    .environmentObject(TaskStore.statisticsPreview)
}

#Preview("Dark, large text") {
    NavigationStack {
        StatisticsView()
    }
    .environmentObject(TaskStore.statisticsPreview)
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility2)
}

#Preview("Landscape", traits: .landscapeLeft) {
    NavigationStack {
        StatisticsView()
    }
    .environmentObject(TaskStore.statisticsPreview)
}
