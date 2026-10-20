//
//  TaskRowView.swift
//  Bun and Done
//
//  Created by Clare Ahn on 20/10/2026.
//
import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void

    // Lets us check if the user has picked a very large text size
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? Color.successGreen : Color.secondaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark as not done" : "Mark as done")

            VStack(alignment: .leading, spacing: 6) {
                // At accessibility sizes there isn't room side by side,
                // so the badge moves under the title instead
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) {
                        titleText
                        dueBadge
                    }
                } else {
                    HStack(alignment: .top) {
                        titleText
                        Spacer()
                        dueBadge
                    }
                }

                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        tagsAndPriority
                    }
                } else {
                    HStack(spacing: 6) {
                        tagsAndPriority
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var titleText: some View {
        Text(task.title)
            .font(.headline)
            .foregroundStyle(task.isCompleted ? Color.secondaryText : Color.primaryText)
            .strikethrough(task.isCompleted)
    }

    @ViewBuilder
    private var dueBadge: some View {
        if task.isCompleted == false {
            Text(task.dueLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(task.dueDate == nil ? Color.secondaryText : Color.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.chipBackground, in: Capsule())
                .accessibilityLabel(task.dueAccessibilityLabel)
        }
    }

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

        Label(task.priority.title, systemImage: "flag.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(task.priority == .high ? Color.accentColor : Color.secondaryText)
            .accessibilityLabel("\(task.priority.title) priority")
    }
}
