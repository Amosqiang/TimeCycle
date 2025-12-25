import BackgroundTasks
import Foundation
import UserNotifications

final class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var statusMessage: String = ""

    private let audioManager = AudioManager.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    private let maxPendingNotifications = 64
    private var batchCycles: Int { maxPendingNotifications / 2 }
    static let refreshTaskIdentifier = "com.timecycle.refresh"
    private let sessionKey = "TimeCycleSession"
    private let repeatingPhaseAPrefix = "repeat_cycle_a_"
    private let repeatingPhaseBPrefix = "repeat_cycle_b_"

    private var session: SessionState?

    init() {
        loadSessionIfNeeded()
    }

    func startCycle(
        phase1Seconds: Int,
        phase1Text: String,
        phase2Seconds: Int,
        phase2Text: String,
        cycles: Int
    ) {
        guard !isRunning else { return }

        statusMessage = ""

        guard cycles > 0 else {
            statusMessage = "Cycles must be at least 1."
            return
        }

        guard phase1Seconds > 0, phase2Seconds > 0 else {
            statusMessage = "Each phase must be greater than 0 seconds."
            return
        }

        let cycleDuration = phase1Seconds + phase2Seconds
        let canRepeatCalendar = cycleDuration <= 60 && cycleDuration > 0 && 60 % cycleDuration == 0
        let repeatsPerMinute = canRepeatCalendar ? (60 / cycleDuration) : 0
        let repeatRequestCount = repeatsPerMinute * 2
        let useRepeatingCalendar = cycles > batchCycles && canRepeatCalendar && repeatRequestCount <= maxPendingNotifications

        requestAuthorizationIfNeeded { [weak self] authorized in
            guard let self else { return }
            guard authorized else {
                DispatchQueue.main.async {
                    self.statusMessage = "Notifications are disabled. Enable them in Settings."
                }
                return
            }

            DispatchQueue.main.async {
                self.clearPendingNotifications()

                let now = Date().timeIntervalSince1970
                let newSession = SessionState(
                    startTime: now,
                    phase1Seconds: phase1Seconds,
                    phase2Seconds: phase2Seconds,
                    phase1Text: phase1Text,
                    phase2Text: phase2Text,
                    totalCycles: cycles,
                    scheduledThroughCycle: 0,
                    usesRepeatingCalendar: useRepeatingCalendar
                )
                self.session = newSession
                self.saveSession(newSession)
                self.isRunning = true

                if useRepeatingCalendar {
                    self.statusMessage = "Repeat mode enabled. Open the app to stop after the set cycles."
                } else if cycles > self.batchCycles {
                    if cycleDuration <= 60 && 60 % cycleDuration != 0 {
                        self.statusMessage = "Short cycles that don't divide 60s still need the app open to continue."
                    } else {
                        self.statusMessage = "iOS schedules 32 cycles at a time. Open the app to continue scheduling."
                    }
                }

                self.refreshScheduleIfNeeded()
            }
        }
    }

    func stopTimer() {
        isRunning = false
        statusMessage = ""
        clearPendingNotifications()
        cancelBackgroundRefresh()
        clearSession()
    }

    func refreshScheduleIfNeeded(completion: ((Bool) -> Void)? = nil) {
        guard var session = session else {
            cancelBackgroundRefresh()
            completion?(true)
            return
        }

        let cycleDuration = session.phase1Seconds + session.phase2Seconds
        guard cycleDuration > 0 else {
            stopTimer()
            completion?(true)
            return
        }

        let now = Date()
        let endTime = session.startTime + TimeInterval(cycleDuration * session.totalCycles)
        if now.timeIntervalSince1970 >= endTime {
            stopTimer()
            completion?(true)
            return
        }

        if session.usesRepeatingCalendar && cycleDuration <= 60 && 60 % cycleDuration == 0 {
            scheduleRepeating(session: session) { [weak self] success in
                guard let self else { return }
                if !success {
                    DispatchQueue.main.async {
                        self.statusMessage = "Some notifications failed to schedule. Please try again."
                    }
                }
                completion?(success)
            }
            return
        }

        let elapsed = max(0, now.timeIntervalSince1970 - session.startTime)
        let currentCycleIndex = Int(elapsed / TimeInterval(cycleDuration))
        if currentCycleIndex >= session.totalCycles {
            stopTimer()
            return
        }

        let scheduledAhead = max(0, session.scheduledThroughCycle - currentCycleIndex)
        if scheduledAhead >= batchCycles {
            scheduleBackgroundRefreshIfNeeded()
            completion?(true)
            return
        }

        let targetCycleIndex = min(session.totalCycles, currentCycleIndex + batchCycles)
        let startIndex = max(session.scheduledThroughCycle, currentCycleIndex)
        guard startIndex < targetCycleIndex else {
            scheduleBackgroundRefreshIfNeeded()
            completion?(true)
            return
        }

        scheduleCycles(
            session: session,
            startIndex: startIndex,
            endIndex: targetCycleIndex
        ) { [weak self] success in
            guard let self else { return }
            if !success {
                DispatchQueue.main.async {
                    self.statusMessage = "Some notifications failed to schedule. Please try again."
                }
                completion?(false)
                return
            }

            session.scheduledThroughCycle = targetCycleIndex
            self.session = session
            self.saveSession(session)
            self.scheduleBackgroundRefreshIfNeeded()
            completion?(true)
        }
    }

    private func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion(granted)
                }
            case .authorized, .provisional:
                completion(true)
            case .denied:
                completion(false)
            default:
                if #available(iOS 14.0, *), settings.authorizationStatus == .ephemeral {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }

    private func scheduleCycles(
        session: SessionState,
        startIndex: Int,
        endIndex: Int,
        completion: @escaping (Bool) -> Void
    ) {
        prepareSoundFiles(phase1Text: session.phase1Text, phase2Text: session.phase2Text) { [weak self] soundNames in
            guard let self else { return }
            guard let soundName1 = soundNames[session.phase1Text],
                  let soundName2 = soundNames[session.phase2Text] else {
                DispatchQueue.main.async {
                    self.statusMessage = "Failed to generate audio. Please try again."
                }
                completion(false)
                return
            }

            self.scheduleCycleNotifications(
                session: session,
                startIndex: startIndex,
                endIndex: endIndex,
                soundName1: soundName1,
                soundName2: soundName2,
                completion: completion
            )
        }
    }

    private func scheduleRepeating(session: SessionState, completion: @escaping (Bool) -> Void) {
        prepareSoundFiles(phase1Text: session.phase1Text, phase2Text: session.phase2Text) { [weak self] soundNames in
            guard let self else { return }
            guard let soundName1 = soundNames[session.phase1Text],
                  let soundName2 = soundNames[session.phase2Text] else {
                DispatchQueue.main.async {
                    self.statusMessage = "Failed to generate audio. Please try again."
                }
                completion(false)
                return
            }

            self.scheduleRepeatingCalendarNotifications(
                session: session,
                soundName1: soundName1,
                soundName2: soundName2,
                completion: completion
            )
        }
    }

    private func prepareSoundFiles(
        phase1Text: String,
        phase2Text: String,
        completion: @escaping ([String: String]) -> Void
    ) {
        let uniqueTexts = Array(Set([phase1Text, phase2Text]))
        var soundNames: [String: String] = [:]
        let group = DispatchGroup()

        for text in uniqueTexts {
            group.enter()
            audioManager.prepareSoundFile(for: text) { fileName in
                if let fileName {
                    soundNames[text] = fileName
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(soundNames)
        }
    }

    private func scheduleCycleNotifications(
        session: SessionState,
        startIndex: Int,
        endIndex: Int,
        soundName1: String?,
        soundName2: String?,
        completion: @escaping (Bool) -> Void
    ) {
        let cycleDuration = session.phase1Seconds + session.phase2Seconds
        let now = Date()
        let group = DispatchGroup()
        var hadError = false

        for index in startIndex..<endIndex {
            let cycleStart = session.startTime + TimeInterval(index * cycleDuration)
            let firstFire = Date(timeIntervalSince1970: cycleStart + TimeInterval(session.phase1Seconds))
            let secondFire = Date(timeIntervalSince1970: cycleStart + TimeInterval(cycleDuration))

            let firstId = "cycle_\(index)_a"
            let secondId = "cycle_\(index)_b"

            let firstInterval = firstFire.timeIntervalSince(now)
            if firstInterval >= 1 {
                group.enter()
                scheduleNotification(
                    interval: firstInterval,
                    text: session.phase1Text,
                    soundName: soundName1,
                    identifier: firstId
                ) { success in
                    if !success { hadError = true }
                    group.leave()
                }
            }

            let secondInterval = secondFire.timeIntervalSince(now)
            if secondInterval >= 1 {
                group.enter()
                scheduleNotification(
                    interval: secondInterval,
                    text: session.phase2Text,
                    soundName: soundName2,
                    identifier: secondId
                ) { success in
                    if !success { hadError = true }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(!hadError)
        }
    }

    private func scheduleRepeatingCalendarNotifications(
        session: SessionState,
        soundName1: String?,
        soundName2: String?,
        completion: @escaping (Bool) -> Void
    ) {
        let cycleDuration = session.phase1Seconds + session.phase2Seconds
        guard cycleDuration > 0, cycleDuration <= 60, 60 % cycleDuration == 0 else {
            completion(false)
            return
        }

        let startDate = Date(timeIntervalSince1970: session.startTime)
        let calendar = Calendar.current
        let startSecond = calendar.component(.second, from: startDate)

        let cyclesPerMinute = 60 / cycleDuration
        var phaseASeconds: [Int] = []
        var phaseBSeconds: [Int] = []

        for index in 0..<cyclesPerMinute {
            let second = (startSecond + (index * cycleDuration) + session.phase1Seconds) % 60
            phaseASeconds.append(second)
        }

        for index in 1...cyclesPerMinute {
            let second = (startSecond + (index * cycleDuration)) % 60
            phaseBSeconds.append(second)
        }

        let uniquePhaseA = Array(Set(phaseASeconds)).sorted()
        let uniquePhaseB = Array(Set(phaseBSeconds)).sorted()
        let totalRequests = uniquePhaseA.count + uniquePhaseB.count
        guard totalRequests <= maxPendingNotifications else {
            completion(false)
            return
        }

        let group = DispatchGroup()
        var hadError = false

        for second in uniquePhaseA {
            group.enter()
            scheduleCalendarNotification(
                second: second,
                text: session.phase1Text,
                soundName: soundName1,
                identifier: "\(repeatingPhaseAPrefix)\(second)"
            ) { success in
                if !success { hadError = true }
                group.leave()
            }
        }

        for second in uniquePhaseB {
            group.enter()
            scheduleCalendarNotification(
                second: second,
                text: session.phase2Text,
                soundName: soundName2,
                identifier: "\(repeatingPhaseBPrefix)\(second)"
            ) { success in
                if !success { hadError = true }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(!hadError)
        }
    }

    private func scheduleNotification(
        interval: TimeInterval,
        text: String,
        soundName: String?,
        identifier: String,
        completion: @escaping (Bool) -> Void
    ) {
        let content = UNMutableNotificationContent()
        content.title = "TimeCycle"
        content.body = text
        if let soundName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        }

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            DispatchQueue.main.async {
                if let error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }

    private func scheduleCalendarNotification(
        second: Int,
        text: String,
        soundName: String?,
        identifier: String,
        completion: @escaping (Bool) -> Void
    ) {
        let content = UNMutableNotificationContent()
        content.title = "TimeCycle"
        content.body = text
        if let soundName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        }

        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let components = DateComponents(second: second)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            DispatchQueue.main.async {
                if let error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }

    private func loadSessionIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey) else { return }
        guard let stored = try? JSONDecoder().decode(SessionState.self, from: data) else { return }

        let cycleDuration = stored.phase1Seconds + stored.phase2Seconds
        if cycleDuration <= 0 {
            clearSession()
            return
        }

        let endTime = stored.startTime + TimeInterval(cycleDuration * stored.totalCycles)
        if Date().timeIntervalSince1970 >= endTime {
            clearSession()
            return
        }

        session = stored
        isRunning = true
    }

    private func saveSession(_ session: SessionState) {
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    private func clearSession() {
        session = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    private func scheduleBackgroundRefreshIfNeeded() {
        guard #available(iOS 13.0, *) else { return }
        guard let session = session, isRunning else { return }
        if session.usesRepeatingCalendar {
            return
        }

        let cycleDuration = session.phase1Seconds + session.phase2Seconds
        guard cycleDuration > 0 else { return }

        let now = Date()
        let scheduledEnd = session.startTime + TimeInterval(session.scheduledThroughCycle * cycleDuration)
        let leadTime = max(TimeInterval(cycleDuration * 4), 60)
        let earliest = max(now.addingTimeInterval(15), Date(timeIntervalSince1970: scheduledEnd - leadTime))

        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = earliest

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskIdentifier)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background refresh: \(error.localizedDescription)")
        }
    }

    private func cancelBackgroundRefresh() {
        guard #available(iOS 13.0, *) else { return }
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskIdentifier)
    }

    private func clearPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    private struct SessionState: Codable {
        var startTime: TimeInterval
        var phase1Seconds: Int
        var phase2Seconds: Int
        var phase1Text: String
        var phase2Text: String
        var totalCycles: Int
        var scheduledThroughCycle: Int
        var usesRepeatingCalendar: Bool

        enum CodingKeys: String, CodingKey {
            case startTime
            case phase1Seconds
            case phase2Seconds
            case phase1Text
            case phase2Text
            case totalCycles
            case scheduledThroughCycle
            case usesRepeatingCalendar
        }

        init(
            startTime: TimeInterval,
            phase1Seconds: Int,
            phase2Seconds: Int,
            phase1Text: String,
            phase2Text: String,
            totalCycles: Int,
            scheduledThroughCycle: Int,
            usesRepeatingCalendar: Bool
        ) {
            self.startTime = startTime
            self.phase1Seconds = phase1Seconds
            self.phase2Seconds = phase2Seconds
            self.phase1Text = phase1Text
            self.phase2Text = phase2Text
            self.totalCycles = totalCycles
            self.scheduledThroughCycle = scheduledThroughCycle
            self.usesRepeatingCalendar = usesRepeatingCalendar
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            startTime = try container.decode(TimeInterval.self, forKey: .startTime)
            phase1Seconds = try container.decode(Int.self, forKey: .phase1Seconds)
            phase2Seconds = try container.decode(Int.self, forKey: .phase2Seconds)
            phase1Text = try container.decode(String.self, forKey: .phase1Text)
            phase2Text = try container.decode(String.self, forKey: .phase2Text)
            totalCycles = try container.decode(Int.self, forKey: .totalCycles)
            scheduledThroughCycle = try container.decode(Int.self, forKey: .scheduledThroughCycle)
            usesRepeatingCalendar = try container.decodeIfPresent(Bool.self, forKey: .usesRepeatingCalendar) ?? false
        }
    }
}
