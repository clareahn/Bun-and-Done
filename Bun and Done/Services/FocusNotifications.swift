//
//  FocusNotifications.swift
//  Bun and Done
//
//  Created by Clare Ahn on 10/11/2026.
//

import UserNotifications
// An enum because it only groups helper functions and stores nothing, so it never needs to be created.
// Schedules and cancels the "focus session complete" notification
enum FocusNotifications {
    // Fixed ID so there's only ever one pending focus notification, and it can be cancelled
    private static let focusEndID = "focusSessionEnd"

    static func requestPermission() {
        // iOS permission pop up
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func scheduleFocusEnd(in seconds: Int) {
        guard seconds > 0 else { return }
        cancelFocusEnd()   // replace any earlier one
        // content = what it says
        let content = UNMutableNotificationContent()
        content.title = "Focus session complete 🥕"
        content.body = "Your carrot is fully grown. Time for a break!"
        content.sound = .default
        // trigger = when
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        // request = what + when + notif fixed id
        let request = UNNotificationRequest(identifier: focusEndID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) // give to iOS to schedule
    }
    // Removes the pending notification (used on pause and reset).
    static func cancelFocusEnd() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [focusEndID])
    }
}
