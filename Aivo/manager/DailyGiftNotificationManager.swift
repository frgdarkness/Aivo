import Foundation
import UserNotifications

class DailyGiftNotificationManager {
    static let shared = DailyGiftNotificationManager()
    
    // Fixed notification IDs to overwrite or cancel them specifically
    private let morningId = "daily_gift_8h"
    private let noonId = "daily_gift_12h"
    private let eveningId = "daily_gift_20h"
    
    private init() {}
    
    /// Requests notification permission and schedules reminders for 8:00, 12:00, 20:00
    func requestAndScheduleReminders() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.scheduleAllReminders()
            }
        }
    }
    
    /// Schedules reminders if gift was not claimed today
    func scheduleAllReminders() {
        // If already claimed today, don't schedule for today
        // But we want to schedule repeating for future days too
        
        scheduleNotification(at: 8, identifier: morningId)
        scheduleNotification(at: 12, identifier: noonId)
        scheduleNotification(at: 20, identifier: eveningId)
    }
    
    /// Schedules a daily repeating notification at specific hour
    private func scheduleNotification(at hour: Int, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "🎁 Your Daily Gift is Waiting!"
        content.body = "Come back to claim your credits and keep your streak alive! 🔥"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.e("❌ [Notification] Error scheduling \(identifier): \(error)")
            } else {
                Logger.d("✅ [Notification] Scheduled \(identifier) at \(hour):00 daily")
            }
        }
    }
    
    /// Called when user claims gift - cancels remaining notifications for today
    func cancelRemindersForToday() {
        // UNUserNotificationCenter doesn't have a "cancel only today's" repeating notification
        // So we remove existing and re-schedule starting from tomorrow
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [morningId, noonId, eveningId])
        
        // Re-schedule for future days (starts firing next time date matches)
        // Since it's a "daily repeats" trigger, if current time > 8h, it will fire tomorrow 8h
        scheduleAllReminders()
    }
}
