// NotificationManager.swift – Local + remote push notification setup

import Foundation
import Combine
import UserNotifications
import UIKit

@MainActor
class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    @Published var authStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
        Task { await refreshStatus() }
    }

    private func registerCategories() {
        let stillHere = UNNotificationAction(identifier: "STILL_HERE",
                                             title: "Ja, ik ben er nog!",
                                             options: [])
        let stopRecap = UNNotificationAction(identifier: "STOP_RECAP",
                                             title: "Stop Recap",
                                             options: [.destructive])
        let idle = UNNotificationCategory(identifier: "IDLE_CHECK",
                                          actions: [stillHere, stopRecap],
                                          intentIdentifiers: [],
                                          options: [])
        UNUserNotificationCenter.current().setNotificationCategories([idle])
    }

    // MARK: – Permission

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            authStatus = granted ? .authorized : .denied
            if granted { scheduleWeeklyReminders() }
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authStatus = settings.authorizationStatus
    }

    // MARK: – Session notifications

    /// Called when user ends a recap session
    func scheduleRecapReady(title: String, stopsCount: Int, steps: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Je Recap is klaar!"
        content.body  = "\"\(title)\" — \(stopsCount) stops, \(steps.formatted()) stappen. Tik om te bekijken."
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "recap_ready_\(UUID().uuidString)",
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Called when user starts a recap — reminds them to end it if still active after 8 hours
    func scheduleSessionReminder() {
        removeNotification(id: "session_reminder")

        let content = UNMutableNotificationContent()
        content.title = "Recap nog actief"
        content.body  = "Je sessie loopt al meer dan 8 uur. Vergeet niet te stoppen!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 8 * 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "session_reminder",
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelSessionReminder() {
        removeNotification(id: "session_reminder")
    }

    // MARK: – Idle check (3h)

    func scheduleIdleCheck() {
        removeNotification(id: "idle_check")

        let idle = UNMutableNotificationContent()
        idle.title = "Ben je er nog?"
        idle.body  = "Je recap loopt al 3 uur. Alles goed?"
        idle.sound = .default
        idle.categoryIdentifier = "IDLE_CHECK"
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "idle_check",
                                  content: idle,
                                  trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3 * 3600, repeats: false))
        )
    }

    func cancelIdleCheck() {
        removeNotification(id: "idle_check")
        UserDefaults.standard.removeObject(forKey: "autoStopRecap")
    }

    // MARK: – Sleep detection (5h no movement → auto-stop)

    func rescheduleSleepCheck() {
        removeNotification(id: "sleep_stop")
        let content = UNMutableNotificationContent()
        content.title = "Recap gestopt — goedemorgen!"
        content.body  = "Je lag 5 uur stil, die zijn afgetrokken van je recap."
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "sleep_stop",
                                  content: content,
                                  trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5 * 3600, repeats: false))
        )
    }

    func cancelSleepCheck() {
        removeNotification(id: "sleep_stop")
    }

    // MARK: – Weekly reminders (Friday + Saturday evening)

    func scheduleWeeklyReminders() {
        removeNotification(id: "weekly_friday")
        removeNotification(id: "weekly_saturday")

        schedule(id: "weekly_friday",
                 title: "Klaar voor vanavond?",
                 body: "Vergeet Recap niet te starten als je de deur uitgaat!",
                 weekday: 6, hour: 19, minute: 0)

        schedule(id: "weekly_saturday",
                 title: "Zaterdagavond!",
                 body: "Tap Start zodra je begint — Recap legt alles automatisch vast.",
                 weekday: 7, hour: 19, minute: 0)
    }

    func cancelWeeklyReminders() {
        removeNotification(id: "weekly_friday")
        removeNotification(id: "weekly_saturday")
    }

    // MARK: – Inactivity reminder (7 days no recap)

    func scheduleInactivityReminder() {
        removeNotification(id: "inactivity")

        let content = UNMutableNotificationContent()
        content.title = "Lang niet gezien!"
        content.body  = "Het is al een tijdje geleden. Klaar voor een nieuwe avond?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7 * 24 * 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "inactivity",
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func resetInactivityReminder() {
        removeNotification(id: "inactivity")
        scheduleInactivityReminder()
    }

    // MARK: – Badge

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: – Helpers

    private func schedule(id: String, title: String, body: String,
                          weekday: Int, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        var components        = DateComponents()
        components.weekday    = weekday
        components.hour       = hour
        components.minute     = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func removeNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
    }
}

// MARK: – Foreground display (show banner even when app is open)

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let notifId   = response.notification.request.identifier
        let actionId  = response.actionIdentifier

        if notifId == "idle_check" {
            if actionId == "STILL_HERE" {
                Task { @MainActor in NotificationManager.shared.scheduleIdleCheck() }
            } else if actionId == "STOP_RECAP" {
                UserDefaults.standard.set(true, forKey: "autoStopRecap")
            }
        } else if notifId == "sleep_stop" {
            UserDefaults.standard.set(true, forKey: "autoStopRecap")
            // sleepAnchorTime was stored in UserDefaults by LocationManager
        }
        completionHandler()
    }
}
