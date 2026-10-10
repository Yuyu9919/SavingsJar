import Foundation
import UserNotifications

/// 本地通知：每日攒钱提醒
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let dailyID = "com.xiaoyu.savingsjar.daily-reminder"

    private override init() { super.init() }

    /// 在 App 启动时调用一次，接管前台展示
    func bootstrap() {
        center.delegate = self
    }

    // MARK: - 权限

    /// 只在用户真正开启提醒开关时才请求权限（不在启动时弹）
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    // MARK: - 每日提醒

    func scheduleDaily(hour: Int, minute: Int = 0) async {
        center.removePendingNotificationRequests(withIdentifiers: [dailyID])
        guard await requestAuthorizationIfNeeded() else { return }

        let content = UNMutableNotificationContent()
        content.title = "今天的攒钱计划还没打卡"
        content.body = "打开攒钱罐，把今天那一格点亮吧～"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelDaily() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyID])
    }

    /// 单个计划的截止日提醒
    func scheduleDeadline(id planID: String, name: String, deadline: Date) async {
        let id = "deadline-\(planID)"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard await requestAuthorizationIfNeeded() else { return }

        let content = UNMutableNotificationContent()
        content.title = "「\(name)」快到期了"
        content.body = "还差一点点，冲一冲就完成了。"
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: deadline)
        components.hour = 10
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
