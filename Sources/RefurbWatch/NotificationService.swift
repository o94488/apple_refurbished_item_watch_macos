import AppKit
import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    var onOpenProduct: ((ProductOpenRequest) -> Void)?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func configure() async {
        let goToWebsite = UNNotificationAction(
            identifier: "SHOW_WEBSITE_CONFIRMATION",
            title: "Review",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "REFURB_IN_STOCK",
            actions: [goToWebsite],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])

        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func sendAvailabilityAlert(for task: WatchTask, product: AppleProduct) {
        let content = UNMutableNotificationContent()
        content.title = "Available at Apple Canada"
        content.subtitle = product.formattedPrice ?? "Matching product found"
        content.body = product.name
        content.categoryIdentifier = "REFURB_IN_STOCK"
        content.threadIdentifier = task.id.uuidString
        content.userInfo = [
            "productName": product.name,
            "productURL": product.url.absoluteString
        ]
        if task.soundEnabled {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "availability-\(task.id.uuidString)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func playStandaloneSound() {
        if let sound = NSSound(named: NSSound.Name("Glass")) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        let name = info["productName"] as? String
        let urlString = info["productURL"] as? String

        if let name, let urlString, let url = URL(string: urlString) {
            DispatchQueue.main.async { [weak self] in
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.forEach { window in
                    if window.canBecomeMain {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                self?.onOpenProduct?(ProductOpenRequest(productName: name, url: url))
            }
        }
        completionHandler()
    }
}
