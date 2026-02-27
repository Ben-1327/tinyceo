import Foundation
import UserNotifications

@MainActor
final class NotificationCenterManager {
    private var authorizationRequested = false
    private var lastCardNotificationAt: Date?
    private var lastCrisisNotificationAt: Date?

    private let cardCooldownSeconds: TimeInterval = 60
    private let crisisCooldownSeconds: TimeInterval = 15 * 60

    func requestAuthorizationIfNeeded() {
        guard !authorizationRequested else {
            return
        }
        authorizationRequested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            // Ignore callback details in v0.1. The app remains playable even when denied.
        }
    }

    func notifyCardArrival(cardCount: Int, inboxCount: Int, enabled: Bool) {
        guard enabled, cardCount > 0 else {
            return
        }
        guard canNotify(last: lastCardNotificationAt, cooldownSeconds: cardCooldownSeconds) else {
            return
        }

        let title = "TinyCEO"
        let body: String
        if cardCount == 1 {
            body = "新しいCEOカードが届きました（受信箱: \(inboxCount)件）。"
        } else {
            body = "\(cardCount)件のCEOカードが届きました（受信箱: \(inboxCount)件）。"
        }

        postNotification(identifier: "tinyceo.card.arrival", title: title, body: body)
        lastCardNotificationAt = Date()
    }

    func notifyCrisis(enabled: Bool) {
        guard enabled else {
            return
        }
        guard canNotify(last: lastCrisisNotificationAt, cooldownSeconds: crisisCooldownSeconds) else {
            return
        }

        postNotification(
            identifier: "tinyceo.crisis.arrival",
            title: "TinyCEO",
            body: "緊急対応が必要です。"
        )
        lastCrisisNotificationAt = Date()
    }

    private func canNotify(last: Date?, cooldownSeconds: TimeInterval) -> Bool {
        guard let last else {
            return true
        }
        return Date().timeIntervalSince(last) >= cooldownSeconds
    }

    private func postNotification(identifier: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
