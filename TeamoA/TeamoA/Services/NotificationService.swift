import Foundation
import UserNotifications
import AppKit

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
        content.userInfo = ["agentId": sessionId.uuidString]
        if sound {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "agent-\(sessionId.uuidString)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let agentIdStr = response.notification.request.content.userInfo["agentId"] as? String,
           let agentId = UUID(uuidString: agentIdStr) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .navigateToAgent,
                    object: nil,
                    userInfo: ["agentId": agentId]
                )
            }
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
