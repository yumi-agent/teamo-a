import Foundation
import UserNotifications
import SwiftUI

class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isPermissionGranted = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isPermissionGranted = granted
            }
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func sendNotification(
        sessionId: UUID,
        sessionName: String,
        title: String,
        body: String,
        sound: Bool = true
    ) {
        guard isPermissionGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo = ["sessionId": sessionId.uuidString]
        if sound {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "session-\(sessionId.uuidString)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    func sendStateChangeNotification(sessionId: UUID, sessionName: String, newState: SessionState) {
        let title: String
        let body: String

        switch newState {
        case .waiting:
            title = "[\(sessionName)] Waiting for Input"
            body = "Agent is waiting for your response"
        case .stopped:
            title = "[\(sessionName)] Completed"
            body = "Agent session has finished"
        case .idle:
            title = "[\(sessionName)] Idle"
            body = "Agent has been idle for a while"
        case .running:
            return // Don't notify for running state
        }

        sendNotification(sessionId: sessionId, sessionName: sessionName, title: title, body: body)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let sessionIdStr = response.notification.request.content.userInfo["sessionId"] as? String,
           let sessionId = UUID(uuidString: sessionIdStr) {
            // Post notification to navigate to this session
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .navigateToSession,
                    object: nil,
                    userInfo: ["sessionId": sessionId]
                )
            }
            // Bring app to front
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
