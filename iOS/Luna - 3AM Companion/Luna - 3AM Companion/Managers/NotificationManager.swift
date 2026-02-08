//
//  NotificationManager.swift
//  Luna - 3AM Companion
//
//  Created by Musa Masalla on 2026/02/05.
//

import Foundation
import UserNotifications
import os.log

private let notificationLogger = Logger(subsystem: "com.luna.companion", category: "Notifications")

@Observable
final class NotificationManager {
    static let shared = NotificationManager()
    
    // MARK: - API
    
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        return try await center.requestAuthorization(options: options)
    }
    
    func scheduleNighttimeReminder(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        
        if enabled {
            // Check authorization status first
            center.getNotificationSettings { settings in
                guard settings.authorizationStatus == .authorized else { return }
                
                // Create content
                let content = UNMutableNotificationContent()
                content.title = "Luna is awake 🦉"
                content.body = "Can't sleep? I'm here to keep you company."
                content.sound = .default
                
                // Create trigger (11:00 PM / 23:00 daily)
                var dateComponents = DateComponents()
                dateComponents.hour = 23
                dateComponents.minute = 0
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                // Create request
                let request = UNNotificationRequest(identifier: "nighttime-reminder", content: content, trigger: trigger)
                
                // Schedule
                center.add(request) { error in
                    if let error = error {
                        notificationLogger.error("Error scheduling notification: \(error)")
                    }
                }
            }
        } else {
            // Cancel if disabled
            center.removePendingNotificationRequests(withIdentifiers: ["nighttime-reminder"])
        }
    }
}
