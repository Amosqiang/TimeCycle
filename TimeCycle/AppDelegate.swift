import BackgroundTasks
import UserNotifications
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: TimerManager.refreshTaskIdentifier, using: nil) { [weak self] task in
                guard let refreshTask = task as? BGAppRefreshTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                self?.handleAppRefresh(task: refreshTask)
            }
        }

        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }

    }

    @available(iOS 13.0, *)
    private func handleAppRefresh(task: BGAppRefreshTask) {
        let timerManager = TimerManager()
        var isCompleted = false

        let finish: (Bool) -> Void = { success in
            guard !isCompleted else { return }
            isCompleted = true
            task.setTaskCompleted(success: success)
        }

        task.expirationHandler = {
            finish(false)
        }

        timerManager.refreshScheduleIfNeeded { success in
            finish(success)
        }
    }
}
