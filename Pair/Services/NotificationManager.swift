import Foundation
import UserNotifications

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    func scheduleWeeklyDropNotification() {
        guard isAuthorized else { return }
        
        // Cancel any existing weekly notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly-drop"])
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Pair"
        content.body = "Pair has found this week's jams"
        content.sound = .default
        
        // Schedule for midnight New York time (EST/EDT)
        var dateComponents = DateComponents()
        dateComponents.hour = 0 // Midnight
        dateComponents.minute = 0
        dateComponents.weekday = 5 // Thursday (weekly drop day)
        dateComponents.timeZone = TimeZone(identifier: "America/New_York")
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly-drop",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Weekly drop notification scheduled for midnight New York time")
            }
        }
    }
    
    func scheduleTestNotification(in seconds: TimeInterval = 5) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Pair"
        content.body = "Pair has found this week's jams"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test-notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule test notification: \(error)")
            }
        }
    }
}
